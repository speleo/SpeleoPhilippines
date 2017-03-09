Scale:=15.00;
MagDecl:=-2.85;
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
        "\def\thhugesize{\size[" & decimal max(optical_zoom*h,0) & "]}" & 
        "\def\thtinysizexxs{\size[" & decimal max(optical_zoom*t*0.6,0) & "]}" & 
        "\def\thhugesizexxl{\size[" & decimal max(optical_zoom*h*1.5,0) & "]}" & 
        "\def\thhugesizexxxl{\size[" & decimal max(optical_zoom*h*1.5*1.5,0) & "]}" & 
        "\def\thhugesizexxxxl{\size[" & decimal max(optical_zoom*h*1.5*1.5*1.5,0) & "]}" 
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


def l_rope_SKBB (expr P, show_anchors, show_rebelays) =
  T:=identity;
  pickup PenC;
  if not show_rebelays:
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
    x = point (length P)-1 of P + whatever * down;
    x = point (length P) of P + whatever * right;
    draw point (length P)-1 of P -- x;
  fi;
  if show_anchors:
    for i:=0 upto length P if show_rebelays: -1 fi:
      thdraw point i of P withpen pencircle scaled 0.25u;
    endfor;
  fi;
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
      pair coord;
      sq_size:=0.12u;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, u);
      pickup PenD;  
      forever:
        t := arctime cas of P;
        coord := point t of P;
        thfill coord+(-sq_size,-sq_size)--coord+(sq_size,-sq_size)--coord+(sq_size,sq_size)--coord+(-sq_size,sq_size)--cycle;
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
current_scrap := "C4HelicopterHoleSE2@C4HelicopterHole";
ATTR__scrap := "C4HelicopterHoleSE2";
beginfig(1);
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1087.63,-34.24) -- (1133.58,-50.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1087.63,-34.24) -- (1058.24,-35.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1058.24,-35.39) -- (1087.63,-34.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1058.24,-35.39) -- (1033.82,-27.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1033.82,-27.04) -- (1058.24,-35.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1033.82,-27.04) -- (1011.42,-26.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1011.42,-26.74) -- (1033.82,-27.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1011.42,-26.74) -- (971.90,-25.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((971.90,-25.09) -- (1011.42,-26.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((971.90,-25.09) -- (943.77,-24.64)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((943.77,-24.64) -- (971.90,-25.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((943.77,-24.64) -- (899.24,-27.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((899.24,-27.04) -- (943.77,-24.64)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((899.24,-27.04) -- (839.67,-27.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((839.67,-27.36) -- (899.24,-27.04)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((839.67,-27.36) -- (819.50,-27.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((819.50,-27.23) -- (839.67,-27.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((819.50,-27.23) -- (768.03,-26.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((768.03,-26.00) -- (819.50,-27.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((768.03,-26.00) -- (717.58,-25.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((717.58,-25.28) -- (768.03,-26.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((717.58,-25.28) -- (656.26,-23.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((656.26,-23.62) -- (717.58,-25.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((656.26,-23.62) -- (600.17,-23.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((600.17,-23.66) -- (656.26,-23.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((600.17,-23.66) -- (522.36,-24.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((522.36,-24.51) -- (600.17,-23.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((522.36,-24.51) -- (460.91,-20.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((460.91,-20.37) -- (522.36,-24.51)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((460.91,-20.37) -- (429.60,-18.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((429.60,-18.89) -- (460.91,-20.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((429.60,-18.89) -- (399.19,-20.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((399.19,-20.65) -- (429.60,-18.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((399.19,-20.65) -- (341.82,-23.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((341.82,-23.20) -- (399.19,-20.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((341.82,-23.20) -- (265.91,-21.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((265.91,-21.80) -- (341.82,-23.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((265.91,-21.80) -- (223.43,-24.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((223.43,-24.15) -- (265.91,-21.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((223.43,-24.15) -- (132.05,-22.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((154.73,-19.59) -- (97.88,-20.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((132.05,-22.13) -- (223.43,-24.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((132.05,-22.13) -- (97.88,-20.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((97.88,-20.95) -- (154.73,-19.59)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((97.88,-20.95) -- (97.88,-20.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((55.32,-21.82) -- (97.88,-20.95)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((55.32,-21.82) -- (4.13,-21.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.13,-21.58) -- (55.32,-21.82)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((4.13,-21.58) -- (-46.56,-17.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-46.56,-17.63) -- (4.13,-21.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-46.56,-17.63) -- (-66.44,-20.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-66.44,-20.01) -- (-46.56,-17.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-66.44,-20.01) -- (-145.66,-20.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-145.66,-20.73) -- (-66.44,-20.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-145.66,-20.73) -- (-195.75,-16.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-195.75,-16.46) -- (-145.66,-20.73)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-195.75,-16.46) -- (-236.34,-14.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-236.34,-14.81) -- (-195.75,-16.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-236.34,-14.81) -- (-257.82,-11.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-257.82,-11.98) -- (-236.34,-14.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-257.82,-11.98) -- (-284.31,-18.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-284.31,-18.63) -- (-257.82,-11.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-284.31,-18.63) -- (-313.97,-17.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-313.97,-17.89) -- (-284.31,-18.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-313.97,-17.89) -- (-344.89,-19.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-344.89,-19.21) -- (-313.97,-17.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-344.89,-19.21) -- (-375.63,-15.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-375.63,-15.44) -- (-344.89,-19.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-375.63,-15.44) -- (-398.90,-16.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-398.90,-16.17) -- (-375.63,-15.44)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-398.90,-16.17) -- (-412.56,-16.85)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-412.56,-16.85) -- (-398.90,-16.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-412.56,-16.85) -- (-483.28,-16.08)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-483.28,-16.08) -- (-412.56,-16.85)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-483.28,-16.08) -- (-519.35,-10.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-519.35,-10.41) -- (-483.28,-16.08)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-519.35,-10.41) -- (-529.31,-10.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-529.31,-10.24) -- (-519.35,-10.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-529.31,-10.24) -- (-550.50,-5.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-550.50,-5.27) -- (-529.31,-10.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-550.50,-5.27) -- (-583.35,-2.93)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-583.35,-2.93) -- (-550.50,-5.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-583.35,-2.93) -- (-600.93,-1.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-600.93,-1.72) -- (-583.35,-2.93)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-600.93,-1.72) -- (-603.75,-2.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-603.75,-2.49) -- (-600.93,-1.72)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-603.75,-2.49) -- (-628.20,-10.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-628.20,-10.58) -- (-603.75,-2.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-628.20,-10.58) -- (-665.37,-13.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-665.37,-13.47) -- (-628.20,-10.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-665.37,-13.47) -- (-729.17,-7.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-729.17,-7.63) -- (-665.37,-13.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-729.17,-7.63) -- (-761.14,-4.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-761.14,-4.53) -- (-729.17,-7.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-761.14,-4.53) -- (-783.88,-3.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-783.88,-3.49) -- (-761.14,-4.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-783.88,-3.49) -- (-806.30,-3.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-806.30,-3.11) -- (-783.88,-3.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-806.30,-3.11) -- (-838.64,-3.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-838.64,-3.40) -- (-806.30,-3.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-838.64,-3.40) -- (-883.70,-0.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-883.70,-0.39) -- (-838.64,-3.40)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-883.70,-0.39) -- (-909.56,-3.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-909.56,-3.19) -- (-883.70,-0.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-909.56,-3.19) -- (-946.42,-3.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-946.42,-3.06) -- (-909.56,-3.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-946.42,-3.06) -- (-969.85,5.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-969.85,5.37) -- (-946.42,-3.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-969.85,5.37) -- (-1001.34,6.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1001.34,6.28) -- (-969.85,5.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1001.34,6.28) -- (-1021.93,9.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1021.93,9.74) -- (-1001.34,6.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1021.93,9.74) -- (-1044.99,11.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1044.99,11.34) -- (-1021.93,9.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1044.99,11.34) -- (-1073.67,13.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1073.67,13.42) -- (-1044.99,11.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1073.67,13.42) -- (-1095.80,13.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1095.80,13.91) -- (-1073.67,13.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1095.80,13.91) -- (-1136.46,24.68)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1136.46,24.68) -- (-1095.80,13.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1136.46,24.68) -- (-1182.99,26.25)));
endfig;
beginfig(2);
draw_upscrap(1)(1,((-1145.62,27.49)
 .. controls (-1145.62,27.49) and (-1145.33,27.40) .. (-1143.50,26.63)
 .. controls (-1141.68,25.86) and (-1142.64,26.54) .. (-1140.34,25.48)
 .. controls (-1138.03,24.42) and (-1137.74,23.18) .. (-1136.21,22.12)
 .. controls (-1134.67,21.07) and (-1134.48,20.78) .. (-1132.56,20.01)
 .. controls (-1130.64,19.24) and (-1125.65,16.65) .. (-1122.48,16.37)
 .. controls (-1119.31,16.08) and (-1118.83,16.94) .. (-1116.53,16.17)
 .. controls (-1114.22,15.41) and (-1114.32,15.12) .. (-1112.78,14.35)
 .. controls (-1111.25,13.58) and (-1111.53,13.39) .. (-1109.52,13.01)
 .. controls (-1107.50,12.63) and (-1108.65,12.43) .. (-1106.16,12.34)
 .. controls (-1103.66,12.24) and (-1105.39,11.76) .. (-1101.74,11.86)
 .. controls (-1098.09,11.96) and (-1101.26,11.38) .. (-1095.79,11.76)
 .. controls (-1090.32,12.15) and (-1091.95,13.20) .. (-1088.02,12.14)
 .. controls (-1084.08,11.09) and (-1081.20,11.08) .. (-1076.40,11.27)
 .. controls (-1071.60,11.46) and (-1072.56,12.52) .. (-1068.91,12.23)
 .. controls (-1065.26,11.95) and (-1066.61,12.72) .. (-1061.71,11.18)
 .. controls (-1056.81,9.65) and (-1056.91,8.69) .. (-1053.55,9.08)
 .. controls (-1050.19,9.46) and (-1051.05,10.04) .. (-1048.08,9.75)
 .. controls (-1045.10,9.47) and (-1046.73,10.33) .. (-1042.22,8.79)
 .. controls (-1037.71,7.25) and (-1038.58,7.25) .. (-1035.50,6.39)
 .. controls (-1032.43,5.52) and (-1031.57,5.14) .. (-1029.07,4.66)
 .. controls (-1026.57,4.18) and (-1027.06,4.27) .. (-1023.98,3.98)
 .. controls (-1020.91,3.69) and (-1021.29,3.02) .. (-1018.03,3.79)
 .. controls (-1014.76,4.56) and (-1016.68,4.94) .. (-1012.27,5.04)
 .. controls (-1007.85,5.14) and (-1008.43,5.04) .. (-1005.17,5.14)
 .. controls (-1001.90,5.24) and (-1002.19,5.14) .. (-998.64,5.33)
 .. controls (-995.09,5.53) and (-994.99,5.62) .. (-992.97,5.43)
 .. controls (-990.96,5.24) and (-994.80,4.57) .. (-988.66,4.37)
 .. controls (-982.51,4.18) and (-982.03,3.22) .. (-978.48,3.12)
 .. controls (-974.93,3.02) and (-975.50,3.22) .. (-974.16,3.02)
 .. controls (-972.82,2.83) and (-971.28,2.74) .. (-970.61,2.54)
 .. controls (-969.94,2.35) and (-969.17,2.64) .. (-968.88,1.77)
 .. controls (-968.59,0.91) and (-968.71,0.43) .. (-968.78,-0.24)
 .. controls (-968.98,-1.97) and (-970.03,-2.35) .. (-967.54,-2.74)
 .. controls (-965.04,-3.12) and (-965.90,-3.41) .. (-963.89,-3.51)
 .. controls (-961.87,-3.60) and (-963.98,-3.31) .. (-959.38,-3.70)
 .. controls (-954.77,-4.08) and (-956.88,-4.27) .. (-952.18,-4.37)
 .. controls (-947.47,-4.47) and (-950.16,-4.95) .. (-945.46,-4.47)
 .. controls (-940.75,-3.99) and (-942.00,-3.22) .. (-938.54,-3.70)
 .. controls (-935.09,-4.18) and (-936.62,-4.66) .. (-931.15,-4.09)
 .. controls (-925.68,-3.51) and (-918.77,-5.82) .. (-915.89,-5.53)
 .. controls (-913.01,-5.24) and (-912.53,-5.43) .. (-907.92,-4.95)
 .. controls (-903.31,-4.47) and (-901.49,-4.38) .. (-898.51,-4.28)
 .. controls (-895.53,-4.18) and (-894.48,-4.47) .. (-890.64,-4.57)
 .. controls (-886.80,-4.66) and (-887.57,-4.66) .. (-882.96,-4.37)
 .. controls (-878.35,-4.09) and (-877.30,-4.18) .. (-873.07,-3.80)
 .. controls (-868.85,-3.41) and (-870.48,-3.41) .. (-866.06,-3.41)
 .. controls (-861.65,-3.41) and (-861.94,-3.99) .. (-858.48,-4.09)
 .. controls (-855.02,-4.18) and (-856.66,-4.18) .. (-853.10,-4.18)
 .. controls (-849.55,-4.18) and (-848.40,-4.57) .. (-845.14,-4.37)
 .. controls (-841.87,-4.18) and (-841.49,-4.28) .. (-838.42,-4.66)
 .. controls (-835.34,-5.05) and (-835.73,-5.72) .. (-831.41,-5.14)
 .. controls (-827.09,-4.57) and (-827.18,-4.47) .. (-823.63,-4.76)
 .. controls (-820.08,-5.05) and (-819.31,-4.57) .. (-817.20,-4.67)
 .. controls (-815.09,-4.77) and (-816.05,-4.77) .. (-813.46,-5.15)
 .. controls (-810.87,-5.54) and (-811.35,-5.35) .. (-806.06,-5.15)
 .. controls (-800.78,-4.96) and (-801.17,-4.76) .. (-796.85,-5.05)
 .. controls (-792.53,-5.33) and (-793.49,-5.72) .. (-789.94,-5.33)
 .. controls (-786.38,-4.95) and (-787.44,-4.94) .. (-784.27,-4.94)
 .. controls (-781.11,-4.94) and (-783.60,-4.66) .. (-779.47,-5.14)
 .. controls (-775.35,-5.62) and (-775.15,-5.14) .. (-771.41,-6.10)
 .. controls (-767.67,-7.07) and (-767.28,-7.55) .. (-764.88,-8.22)
 .. controls (-762.48,-8.89) and (-763.16,-9.28) .. (-760.37,-8.99)
 .. controls (-757.59,-8.70) and (-757.30,-8.51) .. (-755.28,-8.70)
 .. controls (-753.27,-8.90) and (-755.28,-8.99) .. (-751.92,-9.47)
 .. controls (-748.56,-9.95) and (-748.95,-9.47) .. (-746.35,-10.43)
 .. controls (-743.76,-11.39) and (-744.63,-11.30) .. (-742.03,-12.26)
 .. controls (-739.44,-13.22) and (-740.88,-13.12) .. (-737.52,-13.98)
 .. controls (-734.16,-14.85) and (-734.83,-15.90) .. (-731.28,-14.94)
 .. controls (-727.73,-13.98) and (-729.17,-14.08) .. (-725.42,-13.89)
 .. controls (-721.68,-13.70) and (-722.35,-13.02) .. (-718.80,-13.69)
 .. controls (-715.25,-14.37) and (-715.92,-14.27) .. (-712.66,-14.37)
 .. controls (-709.39,-14.46) and (-709.01,-14.27) .. (-705.65,-14.75)
 .. controls (-702.29,-15.23) and (-701.90,-15.61) .. (-697.49,-15.71)
 .. controls (-693.07,-15.80) and (-694.51,-16.09) .. (-689.81,-15.61)
 .. controls (-685.10,-15.13) and (-678.38,-15.61) .. (-677.81,-15.99)
 .. controls (-677.23,-16.37) and (-678.00,-16.37) .. (-675.70,-16.37)
 .. controls (-673.39,-16.37) and (-674.16,-15.22) .. (-667.73,-15.99)
 .. controls (-661.30,-16.75) and (-663.79,-17.43) .. (-659.47,-16.66)
 .. controls (-655.15,-15.89) and (-657.75,-15.41) .. (-652.37,-15.32)
 .. controls (-646.99,-15.22) and (-648.91,-15.51) .. (-643.73,-15.32)
 .. controls (-638.55,-15.12) and (-640.85,-15.51) .. (-636.43,-14.64)
 .. controls (-632.02,-13.78) and (-633.36,-13.97) .. (-630.87,-13.78)
 .. controls (-628.37,-13.59) and (-629.52,-14.16) .. (-627.12,-13.30)
 .. controls (-624.72,-12.44) and (-625.39,-13.11) .. (-623.86,-11.96)
 .. controls (-622.32,-10.81) and (-623.95,-11.57) .. (-621.65,-10.52)
 .. controls (-619.35,-9.46) and (-620.50,-10.42) .. (-617.23,-8.79)
 .. controls (-613.97,-7.16) and (-614.74,-6.97) .. (-611.95,-6.30)
 .. controls (-609.17,-5.63) and (-610.71,-5.24) .. (-608.31,-5.44)
 .. controls (-605.91,-5.63) and (-606.10,-5.92) .. (-603.31,-5.72)
 .. controls (-600.53,-5.53) and (-600.33,-5.43) .. (-598.70,-5.81)
 .. controls (-597.07,-6.20) and (-594.77,-7.06) .. (-593.04,-7.35)
 .. controls (-591.31,-7.63) and (-591.22,-7.35) .. (-588.53,-8.21)
 .. controls (-585.84,-9.07) and (-586.03,-9.07) .. (-584.59,-9.65)
 .. controls (-583.15,-10.23) and (-583.44,-10.71) .. (-581.04,-10.99)
 .. controls (-578.64,-11.28) and (-578.35,-11.76) .. (-574.80,-11.28)
 .. controls (-571.25,-10.80) and (-572.98,-11.67) .. (-567.41,-10.61)
 .. controls (-561.84,-9.56) and (-562.99,-9.27) .. (-560.11,-9.36)
 .. controls (-557.23,-9.46) and (-557.71,-9.75) .. (-555.03,-9.75)
 .. controls (-552.34,-9.75) and (-553.11,-9.75) .. (-549.84,-9.65)
 .. controls (-546.58,-9.56) and (-546.96,-10.13) .. (-544.47,-10.04)
 .. controls (-541.97,-9.95) and (-541.78,-11.67) .. (-539.00,-12.44)
 .. controls (-536.21,-13.21) and (-534.77,-13.12) .. (-531.32,-13.51)
 .. controls (-527.86,-13.89) and (-526.13,-14.56) .. (-522.19,-15.13)
 .. controls (-518.26,-15.70) and (-521.04,-16.28) .. (-514.52,-16.19)
 .. controls (-507.99,-16.09) and (-505.59,-16.86) .. (-501.65,-16.96)
 .. controls (-497.72,-17.05) and (-498.29,-16.29) .. (-494.74,-16.77)
 .. controls (-491.19,-17.25) and (-491.00,-17.25) .. (-487.64,-16.96)
 .. controls (-484.28,-16.67) and (-485.81,-16.87) .. (-480.72,-16.58)
 .. controls (-475.64,-16.29) and (-478.13,-16.39) .. (-473.04,-16.58)
 .. controls (-467.96,-16.77) and (-470.36,-16.39) .. (-463.35,-16.96)
 .. controls (-456.34,-17.54) and (-456.05,-18.11) .. (-452.12,-17.63)
 .. controls (-448.18,-17.15) and (-445.59,-18.11) .. (-442.71,-18.11)
 .. controls (-439.83,-18.11) and (-439.35,-17.83) .. (-436.56,-18.11)
 .. controls (-433.78,-18.40) and (-434.74,-18.98) .. (-429.84,-19.36)
 .. controls (-424.95,-19.75) and (-425.81,-20.03) .. (-422.55,-19.55)
 .. controls (-419.28,-19.07) and (-422.16,-20.03) .. (-415.16,-19.94)
 .. controls (-408.15,-19.84) and (-408.44,-19.46) .. (-404.40,-19.55)
 .. controls (-400.37,-19.65) and (-399.80,-19.65) .. (-397.78,-19.75)
 .. controls (-395.76,-19.84) and (-393.65,-19.65) .. (-390.48,-19.84)
 .. controls (-387.31,-20.03) and (-381.36,-20.03) .. (-378.87,-19.93)
 .. controls (-376.37,-19.84) and (-377.72,-19.45) .. (-374.16,-19.64)
 .. controls (-370.61,-19.84) and (-372.92,-19.74) .. (-368.12,-20.22)
 .. controls (-363.32,-20.70) and (-364.57,-20.99) .. (-361.21,-21.19)
 .. controls (-357.85,-21.38) and (-355.64,-21.67) .. (-353.33,-21.28)
 .. controls (-351.03,-20.90) and (-350.26,-20.81) .. (-348.25,-21.00)
 .. controls (-346.23,-21.19) and (-345.75,-21.10) .. (-343.83,-20.90)
 .. controls (-341.91,-20.71) and (-343.83,-20.90) .. (-340.66,-20.52)
 .. controls (-337.49,-20.13) and (-339.80,-20.23) .. (-333.94,-19.56)
 .. controls (-328.08,-18.89) and (-329.62,-18.41) .. (-325.30,-18.89)
 .. controls (-320.98,-19.37) and (-319.64,-19.37) .. (-317.24,-19.56)
 .. controls (-314.84,-19.75) and (-307.92,-20.33) .. (-306.39,-20.52)
 .. controls (-304.85,-20.71) and (-300.72,-20.71) .. (-296.88,-21.29)
 .. controls (-293.04,-21.86) and (-287.09,-21.19) .. (-284.60,-20.81)
 .. controls (-282.10,-20.42) and (-282.48,-20.42) .. (-280.18,-20.52)
 .. controls (-277.88,-20.61) and (-278.07,-20.90) .. (-276.44,-20.80)
 .. controls (-274.80,-20.71) and (-272.12,-20.71) .. (-266.64,-20.13)
 .. controls (-261.17,-19.55) and (-258.20,-19.93) .. (-255.32,-20.32)
 .. controls (-252.44,-20.70) and (-251.87,-21.18) .. (-249.95,-20.70)
 .. controls (-248.03,-20.23) and (-250.91,-20.22) .. (-246.87,-19.94)
 .. controls (-242.84,-19.65) and (-245.63,-19.27) .. (-240.34,-19.56)
),
1,((-240.34,-19.56)
 .. controls (-240.34,-19.56) and (-237.94,-20.23) .. (-235.54,-19.95)
 .. controls (-233.14,-19.66) and (-230.36,-20.42) .. (-228.34,-19.85)
 .. controls (-226.33,-19.27) and (-224.98,-18.98) .. (-222.29,-19.36)
 .. controls (-219.61,-19.75) and (-218.55,-19.46) .. (-215.38,-19.46)
 .. controls (-212.21,-19.46) and (-211.73,-19.65) .. (-210.77,-19.74)
 .. controls (-209.81,-19.84) and (-212.50,-20.03) .. (-207.99,-20.13)
 .. controls (-203.48,-20.22) and (-200.98,-20.60) .. (-198.29,-20.12)
 .. controls (-195.61,-19.64) and (-196.37,-19.07) .. (-193.11,-19.26)
 .. controls (-189.85,-19.45) and (-190.62,-19.64) .. (-188.12,-19.55)
 .. controls (-185.62,-19.45) and (-186.49,-19.36) .. (-183.80,-19.36)
 .. controls (-181.11,-19.36) and (-179.77,-18.97) .. (-176.02,-19.16)
 .. controls (-172.28,-19.36) and (-173.72,-19.55) .. (-170.74,-19.93)
 .. controls (-167.77,-20.32) and (-169.78,-19.74) .. (-164.89,-20.61)
 .. controls (-159.99,-21.47) and (-160.57,-22.14) .. (-157.02,-21.66)
 .. controls (-153.46,-21.18) and (-153.66,-21.37) .. (-149.72,-21.85)
 .. controls (-145.78,-22.33) and (-147.13,-21.66) .. (-144.63,-22.33)
 .. controls (-142.14,-23.01) and (-139.35,-22.62) .. (-137.43,-22.62)
 .. controls (-135.51,-22.62) and (-134.46,-23.01) .. (-131.29,-23.20)
 .. controls (-128.12,-23.39) and (-121.98,-23.87) .. (-119.96,-23.29)
 .. controls (-117.94,-22.72) and (-118.23,-22.43) .. (-116.12,-22.62)
 .. controls (-114.01,-22.81) and (-110.55,-22.33) .. (-107.86,-21.85)
 .. controls (-105.18,-21.37) and (-104.22,-21.76) .. (-101.72,-21.37)
 .. controls (-99.22,-20.99) and (-99.51,-20.99) .. (-98.36,-20.89)
 .. controls (-97.21,-20.80) and (-99.13,-21.18) .. (-96.54,-20.80)
 .. controls (-93.94,-20.41) and (-92.60,-20.80) .. (-90.20,-20.51)
 .. controls (-87.80,-20.22) and (-89.24,-20.22) .. (-86.84,-20.22)
 .. controls (-84.44,-20.22) and (-85.98,-20.22) .. (-82.71,-20.60)
 .. controls (-79.45,-20.99) and (-78.68,-21.85) .. (-75.99,-21.56)
 .. controls (-73.30,-21.28) and (-70.81,-20.80) .. (-68.79,-21.47)
 .. controls (-66.77,-22.14) and (-63.70,-22.24) .. (-61.49,-22.14)
 .. controls (-59.29,-22.04) and (-61.11,-21.66) .. (-58.71,-22.14)
 .. controls (-56.31,-22.62) and (-53.33,-22.62) .. (-50.93,-22.42)
 .. controls (-48.53,-22.23) and (-47.29,-22.61) .. (-44.12,-22.23)
 .. controls (-40.95,-21.84) and (-44.69,-22.52) .. (-40.18,-21.75)
 .. controls (-35.67,-20.98) and (-38.65,-20.41) .. (-34.33,-20.60)
 .. controls (-30.01,-20.79) and (-32.79,-20.89) .. (-29.05,-20.98)
 .. controls (-25.30,-21.08) and (-26.17,-20.89) .. (-23.19,-21.08)
 .. controls (-20.22,-21.27) and (-20.60,-21.27) .. (-16.57,-21.17)
 .. controls (-12.53,-21.08) and (-13.59,-22.23) .. (-10.23,-21.85)
 .. controls (-6.87,-21.46) and (-6.87,-21.85) .. (-3.61,-22.14)
 .. controls (-0.34,-22.42) and (0.91,-22.90) .. (2.54,-22.90)
 .. controls (4.17,-22.90) and (5.32,-23.19) .. (8.01,-22.90)
 .. controls (10.70,-22.62) and (9.93,-22.42) .. (12.04,-22.52)
 .. controls (14.15,-22.62) and (14.73,-22.62) .. (15.69,-22.71)
 .. controls (16.65,-22.81) and (15.31,-22.90) .. (17.23,-22.81)
 .. controls (19.15,-22.71) and (17.32,-23.58) .. (21.26,-22.61)
 .. controls (25.19,-21.65) and (29.03,-22.81) .. (30.67,-22.71)
 .. controls (32.30,-22.61) and (36.43,-22.81) .. (39.50,-23.00)
 .. controls (42.57,-23.19) and (40.46,-22.71) .. (44.30,-23.19)
 .. controls (48.14,-23.67) and (50.06,-24.72) .. (51.98,-24.34)
 .. controls (53.90,-23.96) and (52.36,-23.67) .. (56.30,-23.86)
 .. controls (60.23,-24.05) and (59.37,-23.67) .. (62.63,-23.76)
 .. controls (65.90,-23.86) and (65.99,-23.86) .. (68.20,-23.86)
 .. controls (70.41,-23.86) and (71.56,-23.96) .. (74.06,-24.34)
 .. controls (76.55,-24.73) and (75.11,-25.02) .. (77.99,-24.64)
 .. controls (80.87,-24.26) and (81.45,-25.51) .. (85.10,-24.83)
 .. controls (88.75,-24.16) and (86.44,-23.97) .. (89.42,-24.16)
 .. controls (92.39,-24.36) and (92.49,-24.55) .. (95.56,-24.16)
 .. controls (98.63,-23.78) and (99.50,-23.94) .. (101.71,-23.78)
 .. controls (104.30,-23.59) and (108.14,-22.82) .. (111.11,-22.72)
 .. controls (114.09,-22.63) and (113.03,-21.76) .. (116.68,-22.43)
 .. controls (120.33,-23.11) and (119.27,-23.30) .. (122.83,-23.39)
 .. controls (126.38,-23.49) and (124.07,-24.26) .. (128.01,-23.49)
 .. controls (131.94,-22.73) and (130.22,-22.25) .. (133.58,-22.73)
 .. controls (136.94,-23.21) and (137.22,-23.88) .. (139.05,-23.88)
 .. controls (140.87,-23.88) and (139.34,-24.74) .. (144.81,-24.74)
 .. controls (150.28,-24.74) and (148.65,-25.22) .. (151.82,-25.03)
 .. controls (154.98,-24.84) and (153.54,-24.93) .. (157.67,-24.65)
 .. controls (161.80,-24.36) and (162.09,-24.26) .. (165.06,-24.17)
 .. controls (168.04,-24.07) and (167.94,-24.26) .. (171.50,-24.26)
 .. controls (175.05,-24.26) and (174.09,-23.78) .. (177.16,-23.97)
 .. controls (180.23,-24.17) and (181.67,-24.64) .. (186.38,-24.26)
 .. controls (191.08,-23.88) and (188.58,-23.49) .. (193.29,-24.74)
 .. controls (197.99,-25.99) and (205.10,-25.32) .. (206.34,-25.03)
 .. controls (207.59,-24.74) and (207.88,-25.60) .. (211.82,-25.41)
 .. controls (215.75,-25.22) and (219.40,-25.51) .. (221.22,-25.89)
 .. controls (223.05,-26.27) and (223.72,-26.75) .. (225.35,-26.75)
 .. controls (226.98,-26.75) and (231.02,-25.70) .. (234.09,-26.08)
 .. controls (237.16,-26.47) and (239.37,-26.47) .. (241.10,-26.27)
 .. controls (242.82,-26.08) and (242.63,-26.47) .. (245.32,-26.08)
 .. controls (248.01,-25.70) and (249.83,-25.41) .. (250.60,-25.60)
),
1,((250.60,-25.60)
 .. controls (250.60,-25.60) and (251.37,-25.70) .. (255.88,-26.66)
 .. controls (260.39,-27.62) and (266.25,-28.00) .. (268.65,-27.62)
 .. controls (271.05,-27.23) and (277.00,-27.42) .. (279.50,-27.33)
 .. controls (281.99,-27.23) and (283.34,-26.56) .. (285.54,-26.46)
 .. controls (287.75,-26.36) and (286.70,-26.56) .. (288.33,-26.27)
 .. controls (289.96,-25.98) and (287.18,-26.17) .. (290.73,-25.60)
 .. controls (294.28,-25.02) and (294.95,-24.83) .. (297.06,-24.83)
 .. controls (299.18,-24.83) and (301.58,-25.11) .. (306.47,-25.40)
 .. controls (311.37,-25.69) and (313.19,-27.22) .. (316.46,-27.32)
 .. controls (319.72,-27.42) and (322.98,-27.32) .. (325.29,-27.32)
 .. controls (327.59,-27.32) and (325.58,-27.70) .. (330.18,-27.22)
 .. controls (334.79,-26.74) and (332.78,-27.03) .. (337.58,-26.36)
 .. controls (342.37,-25.68) and (342.57,-25.30) .. (345.73,-25.69)
 .. controls (348.90,-26.07) and (349.19,-25.97) .. (351.40,-25.88)
 .. controls (353.61,-25.78) and (352.45,-26.74) .. (357.06,-25.50)
 .. controls (361.67,-24.25) and (366.09,-24.54) .. (368.97,-23.96)
 .. controls (371.85,-23.39) and (374.05,-22.91) .. (376.93,-22.43)
 .. controls (379.81,-21.95) and (377.03,-21.95) .. (382.02,-21.66)
 .. controls (387.01,-21.38) and (389.41,-21.38) .. (390.66,-21.38)
 .. controls (391.91,-21.38) and (397.19,-21.57) .. (399.01,-21.76)
 .. controls (400.84,-21.95) and (402.18,-23.01) .. (404.97,-23.20)
 .. controls (407.75,-23.39) and (412.84,-24.06) .. (414.57,-24.06)
 .. controls (416.30,-24.06) and (419.75,-23.77) .. (422.25,-23.96)
 .. controls (424.74,-24.16) and (425.99,-23.10) .. (428.78,-23.10)
 .. controls (431.56,-23.10) and (433.38,-24.15) .. (435.40,-23.58)
 .. controls (437.41,-23.00) and (437.80,-22.52) .. (440.20,-22.52)
 .. controls (442.60,-22.52) and (447.78,-22.61) .. (449.89,-22.52)
 .. controls (452.01,-22.42) and (454.31,-21.85) .. (456.33,-21.85)
 .. controls (458.34,-21.85) and (459.01,-22.90) .. (461.70,-22.71)
 .. controls (464.39,-22.52) and (464.10,-22.42) .. (467.17,-22.71)
 .. controls (470.25,-23.00) and (473.32,-23.67) .. (475.14,-23.57)
 .. controls (476.97,-23.48) and (480.71,-24.63) .. (484.07,-24.44)
 .. controls (487.43,-24.24) and (490.50,-24.34) .. (491.46,-24.53)
 .. controls (492.42,-24.73) and (494.73,-25.01) .. (496.07,-25.21)
 .. controls (497.41,-25.40) and (502.98,-26.36) .. (506.54,-26.17)
 .. controls (510.09,-25.97) and (511.24,-26.55) .. (514.89,-26.07)
 .. controls (518.54,-25.59) and (517.96,-25.20) .. (521.61,-25.40)
 .. controls (525.26,-25.59) and (529.67,-26.07) .. (531.88,-25.88)
 .. controls (534.09,-25.69) and (533.22,-25.59) .. (537.74,-25.88)
 .. controls (542.25,-26.17) and (540.90,-26.07) .. (544.26,-26.07)
 .. controls (547.62,-26.07) and (548.01,-26.55) .. (552.33,-26.55)
),
1,((552.33,-26.55)
 .. controls (552.33,-26.55) and (555.30,-26.75) .. (556.94,-26.46)
 .. controls (558.57,-26.17) and (561.83,-25.79) .. (563.46,-25.59)
 .. controls (565.10,-25.40) and (568.36,-26.75) .. (570.09,-26.65)
 .. controls (571.82,-26.56) and (574.98,-27.13) .. (576.90,-27.23)
 .. controls (578.82,-27.32) and (580.07,-27.80) .. (583.24,-27.61)
 .. controls (586.41,-27.42) and (589.19,-26.56) .. (590.54,-26.37)
 .. controls (591.88,-26.17) and (596.17,-25.91) .. (597.64,-25.98)
 .. controls (603.78,-26.27) and (603.11,-26.27) .. (604.65,-26.27)
 .. controls (606.18,-26.27) and (606.95,-26.56) .. (608.58,-26.27)
 .. controls (610.22,-25.98) and (610.12,-26.08) .. (612.62,-25.89)
 .. controls (615.11,-25.70) and (612.81,-25.50) .. (616.17,-25.60)
 .. controls (619.53,-25.70) and (619.53,-26.08) .. (622.60,-25.60)
 .. controls (625.67,-25.12) and (625.58,-25.60) .. (629.90,-25.70)
 .. controls (634.22,-25.79) and (635.27,-25.60) .. (637.67,-25.22)
 .. controls (640.07,-24.83) and (645.64,-24.06) .. (646.41,-24.35)
 .. controls (647.18,-24.64) and (648.14,-24.93) .. (650.54,-25.31)
 .. controls (652.94,-25.70) and (654.66,-24.93) .. (655.62,-24.83)
 .. controls (656.58,-24.74) and (658.79,-24.74) .. (660.71,-24.83)
 .. controls (662.63,-24.93) and (662.92,-24.93) .. (664.65,-24.93)
 .. controls (666.38,-24.93) and (666.09,-24.64) .. (668.39,-24.93)
 .. controls (670.70,-25.22) and (671.08,-25.98) .. (672.81,-25.79)
 .. controls (674.54,-25.60) and (673.10,-25.31) .. (675.78,-25.41)
 .. controls (678.47,-25.50) and (678.57,-25.98) .. (681.16,-25.60)
 .. controls (683.75,-25.22) and (684.52,-25.70) .. (687.21,-25.50)
 .. controls (689.90,-25.31) and (688.46,-25.12) .. (692.01,-25.22)
 .. controls (695.56,-25.31) and (692.78,-24.93) .. (697.29,-25.41)
 .. controls (701.80,-25.89) and (702.57,-26.75) .. (705.06,-26.56)
 .. controls (707.56,-26.37) and (706.79,-26.66) .. (709.77,-26.47)
 .. controls (712.74,-26.27) and (714.47,-26.75) .. (715.82,-27.04)
 .. controls (717.16,-27.33) and (722.34,-27.91) .. (724.65,-28.10)
 .. controls (726.95,-28.29) and (734.34,-27.62) .. (736.07,-27.42)
 .. controls (737.80,-27.23) and (740.58,-28.10) .. (743.18,-27.71)
 .. controls (745.77,-27.33) and (745.29,-27.04) .. (747.98,-27.04)
 .. controls (750.66,-27.04) and (753.35,-27.13) .. (757.10,-27.33)
 .. controls (760.84,-27.52) and (761.42,-27.33) .. (762.66,-27.61)
 .. controls (763.91,-27.90) and (763.53,-28.29) .. (766.12,-28.48)
 .. controls (768.71,-28.67) and (767.66,-28.29) .. (771.21,-28.57)
 .. controls (774.76,-28.86) and (778.12,-29.63) .. (780.14,-29.43)
 .. controls (782.15,-29.24) and (786.86,-29.14) .. (789.06,-29.14)
 .. controls (791.27,-29.14) and (795.02,-30.20) .. (797.32,-30.01)
 .. controls (799.62,-29.81) and (802.12,-30.29) .. (804.23,-30.10)
 .. controls (806.34,-29.91) and (804.90,-30.00) .. (808.46,-29.81)
 .. controls (812.01,-29.62) and (812.30,-30.48) .. (815.85,-29.43)
 .. controls (819.40,-28.37) and (821.89,-28.56) .. (823.14,-28.37)
 .. controls (824.39,-28.18) and (824.77,-28.27) .. (826.12,-28.47)
 .. controls (827.46,-28.66) and (830.34,-28.75) .. (831.69,-28.66)
 .. controls (833.03,-28.56) and (833.61,-28.95) .. (836.77,-28.66)
 .. controls (839.94,-28.37) and (838.69,-27.99) .. (841.00,-28.28)
 .. controls (843.30,-28.56) and (848.68,-28.66) .. (850.98,-28.37)
 .. controls (853.29,-28.08) and (852.71,-27.51) .. (855.49,-27.89)
 .. controls (858.28,-28.28) and (861.16,-28.66) .. (861.64,-28.66)
 .. controls (862.12,-28.66) and (864.33,-28.95) .. (864.81,-28.95)
 .. controls (865.29,-28.95) and (867.21,-28.95) .. (869.03,-28.95)
 .. controls (870.85,-28.95) and (872.68,-29.14) .. (874.79,-28.76)
 .. controls (876.90,-28.37) and (877.38,-27.89) .. (881.99,-27.99)
 .. controls (886.60,-28.09) and (886.98,-29.05) .. (889.29,-28.57)
 .. controls (891.59,-28.09) and (890.92,-27.70) .. (894.47,-28.09)
 .. controls (898.02,-28.47) and (896.29,-29.14) .. (900.13,-28.86)
 .. controls (903.97,-28.57) and (901.77,-28.66) .. (906.47,-28.76)
 .. controls (911.17,-28.86) and (910.21,-28.86) .. (913.77,-28.38)
 .. controls (917.32,-27.90) and (917.61,-27.99) .. (919.72,-27.99)
 .. controls (921.83,-27.99) and (922.31,-28.09) .. (925.86,-28.09)
 .. controls (929.41,-28.09) and (931.24,-27.99) .. (933.64,-27.70)
 .. controls (936.04,-27.42) and (939.59,-27.13) .. (941.89,-26.74)
 .. controls (944.20,-26.36) and (942.37,-26.26) .. (945.93,-26.26)
 .. controls (949.48,-26.26) and (948.42,-25.88) .. (951.49,-26.07)
 .. controls (954.57,-26.26) and (953.32,-26.36) .. (957.16,-26.64)
 .. controls (961.00,-26.93) and (960.13,-26.84) .. (963.01,-26.93)
 .. controls (965.89,-27.03) and (965.61,-27.51) .. (968.49,-27.41)
 .. controls (971.37,-27.31) and (969.64,-27.02) .. (974.44,-27.22)
 .. controls (979.24,-27.41) and (978.28,-26.93) .. (982.79,-27.22)
),
1,((982.79,-27.22)
 .. controls (982.79,-27.22) and (984.81,-27.22) .. (986.15,-27.41)
 .. controls (987.49,-27.60) and (991.05,-27.99) .. (991.72,-27.51)
 .. controls (992.39,-27.03) and (996.33,-26.65) .. (998.63,-27.22)
 .. controls (1000.93,-27.80) and (1003.72,-27.51) .. (1006.69,-27.99)
 .. controls (1009.67,-28.48) and (1008.71,-28.76) .. (1010.92,-28.48)
 .. controls (1013.13,-28.19) and (1012.93,-28.57) .. (1014.86,-28.67)
 .. controls (1016.78,-28.76) and (1018.31,-29.34) .. (1019.56,-29.05)
 .. controls (1020.81,-28.76) and (1023.88,-28.66) .. (1027.24,-28.18)
 .. controls (1030.60,-27.70) and (1032.61,-27.61) .. (1033.00,-27.99)
 .. controls (1033.38,-28.37) and (1032.90,-28.76) .. (1034.92,-28.85)
 .. controls (1036.93,-28.95) and (1037.80,-28.37) .. (1037.99,-29.05)
 .. controls (1038.18,-29.72) and (1038.47,-29.91) .. (1038.28,-30.29)
 .. controls (1038.09,-30.68) and (1037.70,-30.58) .. (1037.61,-31.54)
 .. controls (1037.51,-32.50) and (1037.51,-33.17) .. (1037.99,-34.33)
 .. controls (1038.47,-35.48) and (1038.28,-36.25) .. (1039.24,-36.73)
 .. controls (1040.20,-37.21) and (1042.40,-38.17) .. (1043.75,-37.98)
 .. controls (1045.09,-37.79) and (1046.34,-37.79) .. (1046.82,-37.88)
 .. controls (1047.30,-37.98) and (1048.64,-38.46) .. (1048.93,-38.94)
 .. controls (1049.22,-39.42) and (1048.61,-38.96) .. (1049.51,-40.29)
 .. controls (1051.14,-42.69) and (1051.14,-42.21) .. (1051.53,-43.36)
 .. controls (1051.91,-44.51) and (1051.91,-44.51) .. (1052.29,-45.18)
 .. controls (1052.68,-45.86) and (1052.49,-46.91) .. (1053.16,-47.10)
 .. controls (1053.83,-47.30) and (1058.15,-47.39) .. (1059.69,-47.49)
 .. controls (1061.22,-47.58) and (1061.51,-47.77) .. (1062.86,-48.45)
 .. controls (1064.20,-49.12) and (1063.62,-48.54) .. (1066.41,-49.60)
 .. controls (1069.19,-50.65) and (1070.35,-51.04) .. (1072.36,-51.52)
 .. controls (1074.38,-51.99) and (1075.53,-52.57) .. (1078.61,-52.47)
 .. controls (1081.68,-52.37) and (1083.41,-52.47) .. (1085.13,-52.85)
 .. controls (1086.86,-53.24) and (1092.34,-53.90) .. (1094.45,-53.42)
 .. controls (1096.56,-52.94) and (1095.41,-53.13) .. (1099.44,-53.52)
 .. controls (1103.47,-53.90) and (1107.22,-55.24) .. (1110.67,-54.57)
 .. controls (1114.13,-53.90) and (1119.12,-53.80) .. (1122.58,-52.93)
 .. controls (1126.03,-52.07) and (1127.76,-51.97) .. (1129.49,-51.78)
 .. controls (1131.22,-51.59) and (1134.58,-51.40) .. (1135.63,-51.49)
 .. controls (1136.69,-51.59) and (1139.95,-51.68) .. (1141.20,-51.59)
 .. controls (1142.45,-51.49) and (1145.62,-51.68) .. (1145.62,-51.68)
),
1,((1095.48,53.52)
 .. controls (1094.14,54.00) and (1093.57,53.71) .. (1092.80,53.90)
 .. controls (1092.03,54.09) and (1087.13,54.48) .. (1086.08,54.19)
 .. controls (1085.02,53.90) and (1078.11,53.13) .. (1074.66,53.42)
 .. controls (1071.20,53.71) and (1069.57,54.09) .. (1065.34,54.47)
 .. controls (1061.12,54.86) and (1060.64,53.99) .. (1059.11,54.47)
 .. controls (1057.57,54.95) and (1057.09,54.09) .. (1054.98,54.47)
 .. controls (1052.87,54.86) and (1053.06,55.24) .. (1049.12,54.67)
 .. controls (1045.19,54.09) and (1043.75,53.03) .. (1040.68,52.07)
 .. controls (1037.60,51.11) and (1036.16,50.15) .. (1036.16,50.15)
 .. controls (1036.16,50.15) and (1032.23,45.16) .. (1031.56,44.59)
 .. controls (1030.88,44.01) and (1031.17,43.34) .. (1029.54,41.51)
 .. controls (1027.91,39.69) and (1028.96,42.09) .. (1026.95,38.35)
 .. controls (1024.93,34.60) and (1023.59,31.34) .. (1022.63,29.80)
 .. controls (1021.67,28.27) and (1020.52,27.21) .. (1019.08,26.44)
 .. controls (1017.64,25.67) and (1012.07,20.11) .. (1010.92,19.34)
 .. controls (1009.77,18.57) and (1008.23,16.36) .. (1004.77,14.54)
 .. controls (1001.32,12.71) and (999.88,10.79) .. (996.81,9.74)
 .. controls (993.73,8.68) and (990.28,9.36) .. (985.96,9.55)
 .. controls (981.64,9.74) and (982.98,8.97) .. (978.18,9.55)
 .. controls (973.38,10.13) and (974.15,9.07) .. (969.16,9.65)
 .. controls (964.17,10.22) and (964.17,10.12) .. (960.04,9.93)
 .. controls (955.91,9.74) and (954.18,9.55) .. (953.12,9.45)
 .. controls (952.07,9.36) and (944.58,9.16) .. (942.95,9.16)
 .. controls (941.32,9.16) and (940.36,9.26) .. (932.96,8.97)
 .. controls (925.57,8.68) and (927.40,8.39) .. (922.31,8.39)
 .. controls (917.22,8.39) and (912.90,7.53) .. (910.21,8.01)
 .. controls (907.53,8.49) and (902.63,9.73) .. (899.46,9.45)
 .. controls (896.30,9.16) and (891.69,8.78) .. (888.52,8.58)
 .. controls (885.35,8.39) and (884.49,7.82) .. (880.84,7.82)
 .. controls (877.19,7.82) and (875.08,6.19) .. (871.82,7.43)
 .. controls (868.55,8.68) and (870.76,8.01) .. (866.63,9.74)
 .. controls (862.50,11.47) and (860.10,12.91) .. (858.76,13.29)
 .. controls (857.42,13.68) and (856.55,14.16) .. (855.11,14.16)
 .. controls (853.67,14.16) and (853.58,15.02) .. (851.75,14.54)
 .. controls (849.93,14.06) and (850.02,14.44) .. (848.58,13.58)
 .. controls (847.14,12.72) and (845.13,11.18) .. (843.50,10.12)
 .. controls (841.86,9.07) and (840.52,7.44) .. (838.50,6.19)
 .. controls (836.49,4.94) and (836.01,3.41) .. (833.99,2.73)
 .. controls (831.97,2.06) and (831.69,1.77) .. (830.05,1.39)
),
1,((830.05,1.39)
 .. controls (830.05,1.39) and (827.17,1.01) .. (825.54,1.87)
 .. controls (823.91,2.73) and (822.47,2.93) .. (819.59,4.56)
 .. controls (816.71,6.19) and (812.49,8.40) .. (810.09,9.07)
 .. controls (807.68,9.74) and (807.40,10.51) .. (802.98,10.80)
 .. controls (798.56,11.08) and (796.64,11.75) .. (794.24,12.14)
 .. controls (791.84,12.52) and (794.15,12.71) .. (788.96,12.52)
 .. controls (783.78,12.33) and (782.15,11.08) .. (779.65,11.46)
 .. controls (777.15,11.84) and (779.07,12.33) .. (775.23,11.94)
 .. controls (771.39,11.56) and (771.01,11.27) .. (768.99,11.27)
 .. controls (766.98,11.27) and (761.89,11.36) .. (759.11,11.94)
 .. controls (756.32,12.51) and (751.72,14.43) .. (746.15,13.95)
 .. controls (740.58,13.47) and (740.29,13.28) .. (737.32,13.28)
 .. controls (734.34,13.28) and (737.32,14.62) .. (730.41,13.37)
 .. controls (723.49,12.13) and (726.85,12.32) .. (721.86,11.55)
 .. controls (716.87,10.78) and (716.49,11.55) .. (711.88,9.44)
 .. controls (707.27,7.33) and (704.10,5.89) .. (702.38,5.41)
 .. controls (700.65,4.93) and (700.94,5.31) .. (696.90,4.16)
 .. controls (692.87,3.01) and (692.49,3.49) .. (688.94,2.05)
 .. controls (685.39,0.61) and (683.85,0.03) .. (682.31,-0.54)
 .. controls (680.78,-1.12) and (679.05,-0.06) .. (675.21,-1.22)
 .. controls (671.37,-2.37) and (669.35,-3.04) .. (667.43,-3.52)
 .. controls (665.51,-4.00) and (663.21,-5.44) .. (658.60,-5.92)
 .. controls (653.99,-6.40) and (655.34,-6.30) .. (651.21,-6.78)
 .. controls (647.08,-7.26) and (646.70,-7.74) .. (641.90,-8.61)
 .. controls (637.10,-9.47) and (637.19,-10.05) .. (632.20,-9.85)
 .. controls (627.21,-9.66) and (628.46,-8.42) .. (623.66,-9.28)
 .. controls (618.86,-10.14) and (619.82,-9.95) .. (615.40,-10.34)
 .. controls (610.98,-10.72) and (613.77,-10.43) .. (608.68,-11.30)
 .. controls (603.59,-12.16) and (602.15,-11.58) .. (600.81,-12.16)
 .. controls (599.46,-12.73) and (595.82,-14.46) .. (592.26,-14.46)
 .. controls (588.71,-14.46) and (586.03,-14.08) .. (581.61,-14.75)
 .. controls (577.19,-15.42) and (577.67,-16.00) .. (573.54,-16.19)
 .. controls (569.42,-16.38) and (571.43,-15.61) .. (565.77,-16.19)
 .. controls (560.10,-16.76) and (561.74,-17.05) .. (557.51,-16.19)
 .. controls (553.29,-15.32) and (556.07,-15.61) .. (548.97,-14.46)
),
1,((548.97,-14.46)
 .. controls (548.97,-14.46) and (547.53,-15.13) .. (546.28,-14.94)
 .. controls (545.03,-14.74) and (540.81,-13.50) .. (538.02,-12.82)
 .. controls (535.24,-12.15) and (531.02,-11.57) .. (528.62,-11.38)
 .. controls (526.22,-11.19) and (522.86,-10.42) .. (516.14,-9.94)
 .. controls (509.42,-9.46) and (510.47,-9.94) .. (507.88,-9.56)
 .. controls (505.29,-9.17) and (502.98,-8.88) .. (499.24,-8.12)
 .. controls (495.50,-7.35) and (494.82,-7.54) .. (491.75,-6.58)
 .. controls (488.68,-5.62) and (487.91,-5.52) .. (485.51,-4.37)
 .. controls (483.11,-3.22) and (486.95,-5.24) .. (480.52,-1.78)
 .. controls (474.09,1.68) and (470.44,2.06) .. (468.52,2.92)
 .. controls (466.60,3.79) and (461.51,3.98) .. (460.74,3.98)
 .. controls (459.97,3.98) and (455.27,1.58) .. (454.21,1.19)
 .. controls (453.16,0.81) and (446.82,-0.34) .. (444.90,-0.44)
 .. controls (442.98,-0.53) and (436.83,0.71) .. (433.38,0.61)
 .. controls (429.92,0.52) and (430.79,1.09) .. (427.14,0.23)
 .. controls (423.49,-0.64) and (425.03,-1.02) .. (420.03,-1.40)
 .. controls (415.04,-1.79) and (411.88,-2.66) .. (409.09,-2.56)
 .. controls (406.31,-2.47) and (407.27,-3.04) .. (404.39,-2.37)
 .. controls (401.51,-1.70) and (402.37,-3.14) .. (399.01,-1.70)
 .. controls (395.65,-0.26) and (396.52,-0.16) .. (394.50,0.03)
 .. controls (392.49,0.22) and (385.58,1.66) .. (385.58,1.66)
),
1,((385.58,1.66)
 .. controls (385.58,1.66) and (384.90,1.09) .. (382.70,0.89)
 .. controls (380.49,0.70) and (378.76,0.32) .. (374.73,1.09)
 .. controls (370.70,1.86) and (371.66,2.05) .. (366.38,1.67)
 .. controls (361.10,1.29) and (360.33,0.13) .. (356.68,0.04)
 .. controls (353.03,-0.05) and (354.66,-0.06) .. (349.00,0.62)
 .. controls (343.34,1.29) and (336.42,1.67) .. (334.02,2.54)
 .. controls (331.62,3.40) and (332.78,3.11) .. (327.11,3.31)
 .. controls (321.45,3.50) and (320.58,2.44) .. (316.74,2.92)
 .. controls (312.90,3.40) and (311.08,4.84) .. (307.04,4.45)
 .. controls (303.01,4.07) and (298.31,3.40) .. (298.31,3.40)
 .. controls (298.31,3.40) and (292.45,2.63) .. (290.34,2.24)
 .. controls (288.23,1.86) and (284.10,2.34) .. (281.22,2.53)
 .. controls (278.34,2.72) and (275.27,2.82) .. (271.14,2.62)
 .. controls (267.01,2.43) and (265.19,1.66) .. (262.31,1.38)
 .. controls (259.43,1.09) and (259.72,0.51) .. (256.45,0.41)
 .. controls (253.19,0.32) and (254.25,0.22) .. (249.06,0.51)
 .. controls (243.88,0.80) and (246.66,0.22) .. (240.04,1.18)
 .. controls (233.41,2.14) and (233.70,2.62) .. (228.81,2.62)
 .. controls (223.91,2.62) and (225.54,2.81) .. (220.55,2.24)
 .. controls (215.56,1.66) and (212.01,1.85) .. (209.61,1.37)
 .. controls (207.21,0.89) and (203.94,-0.55) .. (201.64,-0.84)
 .. controls (199.34,-1.12) and (194.15,-0.55) .. (190.02,-0.74)
 .. controls (185.90,-0.93) and (188.78,-1.12) .. (182.73,-1.22)
 .. controls (176.68,-1.32) and (178.12,-1.03) .. (170.73,-1.12)
 .. controls (163.34,-1.22) and (164.68,-1.03) .. (159.40,-0.64)
 .. controls (154.12,-0.26) and (157.96,-0.74) .. (149.61,0.60)
 .. controls (141.26,1.95) and (143.37,1.66) .. (140.01,1.47)
 .. controls (136.65,1.28) and (134.15,1.66) .. (131.18,1.66)
 .. controls (128.20,1.66) and (126.28,2.14) .. (124.36,1.85)
),
1,((124.36,1.85)
 .. controls (124.36,1.85) and (121.67,1.37) .. (119.18,0.99)
 .. controls (116.68,0.60) and (113.61,1.08) .. (110.25,1.18)
 .. controls (106.89,1.28) and (106.41,1.57) .. (102.57,1.95)
 .. controls (98.73,2.33) and (98.73,2.81) .. (94.60,3.01)
 .. controls (90.47,3.20) and (90.86,2.91) .. (86.44,3.01)
 .. controls (82.02,3.11) and (81.74,2.72) .. (77.70,2.44)
 .. controls (73.67,2.15) and (75.30,1.29) .. (67.05,1.29)
 .. controls (58.79,1.29) and (58.02,2.44) .. (54.86,1.96)
 .. controls (51.69,1.48) and (52.36,1.48) .. (48.62,1.10)
 .. controls (44.87,0.72) and (36.33,2.44) .. (32.78,2.15)
 .. controls (29.22,1.87) and (27.98,1.58) .. (24.42,1.58)
 .. controls (20.87,1.58) and (19.62,1.10) .. (13.77,1.00)
 .. controls (7.91,0.90) and (9.16,0.71) .. (4.84,0.04)
 .. controls (0.52,-0.63) and (2.73,-0.92) .. (-3.22,-0.54)
 .. controls (-9.17,-0.15) and (-8.60,-0.82) .. (-14.07,-0.05)
 .. controls (-19.54,0.71) and (-18.01,1.58) .. (-21.46,0.91)
 .. controls (-24.92,0.24) and (-32.70,-0.72) .. (-34.04,-0.72)
 .. controls (-35.38,-0.72) and (-35.19,-0.92) .. (-36.92,-0.72)
 .. controls (-38.65,-0.53) and (-45.08,0.14) .. (-47.87,-0.44)
 .. controls (-50.65,-1.01) and (-53.72,-1.59) .. (-56.03,-2.55)
 .. controls (-58.33,-3.51) and (-59.29,-4.47) .. (-62.17,-6.01)
 .. controls (-65.05,-7.55) and (-66.01,-9.47) .. (-67.55,-10.62)
 .. controls (-69.08,-11.77) and (-68.70,-12.35) .. (-70.14,-12.54)
 .. controls (-71.58,-12.73) and (-71.77,-13.40) .. (-74.94,-13.69)
 .. controls (-78.10,-13.98) and (-80.98,-14.84) .. (-83.19,-14.27)
 .. controls (-85.40,-13.69) and (-85.02,-13.69) .. (-89.24,-12.92)
 .. controls (-93.46,-12.16) and (-92.12,-11.87) .. (-96.92,-11.48)
 .. controls (-101.72,-11.10) and (-102.01,-10.14) .. (-105.37,-10.05)
 .. controls (-108.73,-9.95) and (-111.32,-9.37) .. (-112.76,-9.85)
),
1,((-112.76,-9.85)
 .. controls (-112.76,-9.85) and (-116.12,-11.58) .. (-119.10,-11.77)
 .. controls (-122.07,-11.97) and (-123.13,-11.68) .. (-126.97,-11.68)
 .. controls (-130.81,-11.68) and (-135.61,-12.83) .. (-139.26,-11.87)
 .. controls (-142.90,-10.91) and (-142.42,-10.05) .. (-145.50,-11.01)
 .. controls (-148.57,-11.97) and (-150.58,-11.29) .. (-155.86,-12.93)
 .. controls (-161.14,-14.56) and (-162.30,-15.04) .. (-165.37,-14.56)
 .. controls (-168.44,-14.08) and (-165.85,-14.46) .. (-169.78,-13.50)
 .. controls (-173.72,-12.54) and (-175.16,-12.92) .. (-176.79,-11.20)
 .. controls (-178.42,-9.47) and (-180.73,-6.97) .. (-181.69,-5.34)
 .. controls (-182.65,-3.71) and (-182.74,-4.19) .. (-183.90,-1.98)
 .. controls (-185.05,0.23) and (-186.49,3.40) .. (-187.35,4.64)
 .. controls (-188.22,5.89) and (-188.79,6.28) .. (-190.23,6.85)
 .. controls (-191.67,7.43) and (-190.62,7.72) .. (-192.44,7.62)
),
1,((-192.44,7.62)
 .. controls (-192.44,7.62) and (-201.08,9.25) .. (-203.77,8.00)
 .. controls (-206.46,6.75) and (-206.75,5.98) .. (-209.24,4.93)
 .. controls (-211.74,3.87) and (-210.78,4.35) .. (-213.27,2.91)
 .. controls (-215.77,1.47) and (-217.59,1.95) .. (-219.70,1.95)
 .. controls (-221.82,1.94) and (-226.23,2.04) .. (-228.05,4.63)
 .. controls (-229.88,7.22) and (-232.56,10.68) .. (-233.14,11.83)
 .. controls (-233.72,12.99) and (-234.39,18.84) .. (-236.31,21.25)
 .. controls (-238.23,23.65) and (-241.21,27.39) .. (-242.07,28.06)
 .. controls (-242.93,28.74) and (-244.57,31.14) .. (-246.39,30.46)
 .. controls (-248.21,29.79) and (-247.83,29.98) .. (-251.00,28.16)
 .. controls (-254.16,26.34) and (-254.74,26.63) .. (-256.95,24.03)
 .. controls (-259.16,21.44) and (-262.23,15.68) .. (-262.90,15.11)
 .. controls (-263.57,14.53) and (-268.76,9.73) .. (-269.53,8.96)
 .. controls (-270.29,8.20) and (-272.41,3.97) .. (-274.42,3.11)
),
1,((-274.42,3.11)
 .. controls (-274.42,3.11) and (-274.23,3.11) .. (-277.11,1.76)
 .. controls (-279.99,0.41) and (-283.35,-1.03) .. (-287.10,-1.32)
 .. controls (-290.84,-1.61) and (-291.03,-3.05) .. (-293.72,-2.28)
 .. controls (-296.41,-1.51) and (-297.94,-2.09) .. (-299.57,-0.26)
 .. controls (-301.21,1.56) and (-303.99,4.83) .. (-304.76,6.07)
 .. controls (-305.53,7.32) and (-305.53,7.90) .. (-306.58,8.67)
 .. controls (-307.64,9.43) and (-309.17,10.30) .. (-312.24,9.43)
 .. controls (-315.32,8.57) and (-317.43,7.99) .. (-318.77,7.23)
 .. controls (-320.12,6.46) and (-321.84,4.44) .. (-322.90,3.67)
 .. controls (-323.96,2.91) and (-326.74,0.03) .. (-328.28,-1.61)
 .. controls (-329.81,-3.24) and (-331.35,-5.06) .. (-333.08,-5.26)
 .. controls (-334.80,-5.45) and (-338.83,-4.30) .. (-339.51,-3.62)
 .. controls (-340.18,-2.95) and (-340.27,-2.09) .. (-342.67,-1.03)
 .. controls (-345.07,0.03) and (-345.46,0.31) .. (-347.47,0.89)
 .. controls (-349.49,1.47) and (-352.27,2.81) .. (-353.52,3.01)
 .. controls (-354.77,3.20) and (-358.99,3.87) .. (-360.63,4.64)
 .. controls (-362.26,5.41) and (-364.37,6.27) .. (-366.39,6.18)
 .. controls (-368.40,6.08) and (-368.21,5.41) .. (-371.19,3.97)
 .. controls (-374.16,2.53) and (-373.97,1.86) .. (-376.56,1.00)
 .. controls (-379.16,0.13) and (-379.06,-0.64) .. (-382.42,-1.02)
 .. controls (-385.78,-1.41) and (-389.14,-2.27) .. (-392.02,-1.79)
 .. controls (-394.90,-1.31) and (-394.42,-0.93) .. (-396.63,-0.55)
 .. controls (-398.84,-0.16) and (-402.97,1.47) .. (-406.13,0.41)
 .. controls (-409.30,-0.64) and (-407.96,-0.45) .. (-410.74,-1.12)
 .. controls (-413.52,-1.80) and (-416.12,-1.51) .. (-420.44,-2.27)
 .. controls (-424.76,-3.04) and (-425.62,-3.23) .. (-429.08,-3.43)
 .. controls (-432.53,-3.62) and (-441.27,-4.29) .. (-443.09,-4.10)
 .. controls (-444.92,-3.91) and (-447.32,-3.71) .. (-451.44,-3.62)
 .. controls (-455.57,-3.52) and (-456.44,-2.75) .. (-459.89,-2.47)
 .. controls (-463.35,-2.18) and (-466.90,-2.18) .. (-469.20,-2.18)
 .. controls (-471.51,-2.18) and (-476.88,-3.23) .. (-480.72,-3.04)
 .. controls (-484.56,-2.85) and (-484.18,-2.75) .. (-486.29,-3.14)
 .. controls (-488.40,-3.52) and (-494.64,-5.44) .. (-496.18,-5.53)
),
1,((-496.18,-5.53)
 .. controls (-496.18,-5.53) and (-498.58,-6.59) .. (-500.50,-6.59)
 .. controls (-502.42,-6.59) and (-504.63,-5.44) .. (-506.83,-4.28)
 .. controls (-509.04,-3.13) and (-509.43,-2.65) .. (-511.06,-0.34)
 .. controls (-512.69,1.96) and (-513.08,1.19) .. (-514.23,4.07)
 .. controls (-515.38,6.95) and (-515.29,6.37) .. (-516.25,8.77)
 .. controls (-517.20,11.17) and (-517.11,15.30) .. (-518.93,15.20)
 .. controls (-520.76,15.11) and (-522.87,14.92) .. (-524.12,14.05)
 .. controls (-525.36,13.19) and (-527.76,10.50) .. (-528.92,10.12)
 .. controls (-530.07,9.73) and (-529.49,8.29) .. (-532.08,8.96)
 .. controls (-534.67,9.64) and (-534.87,9.16) .. (-535.54,10.02)
 .. controls (-536.21,10.88) and (-536.40,11.17) .. (-537.94,12.42)
 .. controls (-539.47,13.67) and (-540.82,14.82) .. (-541.78,15.59)
 .. controls (-542.74,16.36) and (-544.37,17.90) .. (-544.85,18.28)
 .. controls (-545.33,18.67) and (-548.59,20.59) .. (-549.36,21.26)
 .. controls (-550.13,21.93) and (-551.66,22.89) .. (-552.62,23.37)
 .. controls (-553.58,23.85) and (-558.29,25.87) .. (-560.59,25.78)
 .. controls (-562.90,25.68) and (-563.28,26.07) .. (-565.88,24.82)
 .. controls (-568.47,23.57) and (-579.70,20.69) .. (-581.43,20.21)
 .. controls (-583.16,19.73) and (-586.52,17.81) .. (-590.08,17.72)
 .. controls (-593.63,17.62) and (-591.32,16.95) .. (-594.59,17.71)
 .. controls (-597.86,18.48) and (-600.74,20.11) .. (-601.70,21.07)
 .. controls (-602.66,22.03) and (-603.14,22.31) .. (-604.48,24.14)
 .. controls (-605.83,25.96) and (-606.79,28.17) .. (-608.23,28.26)
 .. controls (-609.67,28.36) and (-613.41,27.01) .. (-614.95,26.24)
 .. controls (-616.49,25.47) and (-616.49,26.34) .. (-617.92,24.32)
 .. controls (-619.36,22.30) and (-620.99,21.06) .. (-622.62,19.23)
 .. controls (-624.25,17.41) and (-625.40,15.30) .. (-625.98,14.72)
),
1,((-625.98,14.72)
 .. controls (-625.98,14.72) and (-627.22,13.66) .. (-628.18,12.51)
 .. controls (-629.14,11.36) and (-633.74,6.76) .. (-636.43,5.61)
 .. controls (-639.12,4.46) and (-640.85,3.50) .. (-643.15,3.31)
 .. controls (-645.46,3.12) and (-649.59,1.29) .. (-651.22,0.72)
 .. controls (-652.85,0.14) and (-653.43,-1.20) .. (-656.88,-1.01)
 .. controls (-660.34,-0.82) and (-659.47,-1.11) .. (-662.55,-1.20)
 .. controls (-665.62,-1.30) and (-669.36,-1.78) .. (-673.01,-1.78)
 .. controls (-676.66,-1.78) and (-674.07,-2.74) .. (-680.11,-2.36)
 .. controls (-686.16,-1.98) and (-684.15,-1.98) .. (-688.66,-1.40)
 .. controls (-693.17,-0.83) and (-696.43,-1.31) .. (-699.41,-0.73)
 .. controls (-702.39,-0.16) and (-706.13,-0.35) .. (-709.39,0.23)
 .. controls (-712.66,0.80) and (-711.70,0.99) .. (-714.87,0.71)
 .. controls (-718.03,0.42) and (-715.54,-0.45) .. (-720.24,0.42)
 .. controls (-724.95,1.28) and (-723.89,1.09) .. (-727.83,2.05)
 .. controls (-731.76,3.01) and (-732.91,3.01) .. (-735.31,3.68)
 .. controls (-737.71,4.35) and (-735.02,1.63) .. (-741.07,5.98)
 .. controls (-748.94,11.65) and (-751.82,15.10) .. (-753.07,15.49)
 .. controls (-754.32,15.87) and (-755.28,16.16) .. (-756.43,16.45)
 .. controls (-757.58,16.74) and (-763.82,13.48) .. (-765.07,13.00)
 .. controls (-766.32,12.52) and (-767.95,11.37) .. (-769.68,10.70)
 .. controls (-771.41,10.03) and (-769.87,9.74) .. (-774.00,9.16)
 .. controls (-778.13,8.59) and (-777.84,8.78) .. (-779.57,8.21)
 .. controls (-781.30,7.63) and (-779.18,8.40) .. (-782.55,7.92)
 .. controls (-785.91,7.44) and (-785.04,7.82) .. (-787.54,7.44)
 .. controls (-790.04,7.05) and (-789.07,6.38) .. (-791.00,7.24)
 .. controls (-792.92,8.11) and (-789.65,7.34) .. (-795.03,8.49)
 .. controls (-800.40,9.63) and (-798.68,9.16) .. (-802.04,9.54)
 .. controls (-805.40,9.92) and (-803.09,8.96) .. (-807.03,10.59)
 .. controls (-810.96,12.22) and (-808.56,11.46) .. (-811.92,12.70)
 .. controls (-815.28,13.95) and (-815.47,14.91) .. (-818.26,14.82)
),
1,((-818.26,14.82)
 .. controls (-818.26,14.82) and (-815.86,15.49) .. (-819.79,14.43)
 .. controls (-823.73,13.38) and (-820.18,14.24) .. (-824.59,13.48)
 .. controls (-829.01,12.71) and (-834.86,12.52) .. (-837.17,12.14)
 .. controls (-839.47,11.75) and (-836.78,12.04) .. (-841.49,11.75)
 .. controls (-846.19,11.47) and (-847.53,11.18) .. (-850.80,11.75)
 .. controls (-854.06,12.33) and (-852.82,12.23) .. (-856.56,12.52)
 .. controls (-860.30,12.81) and (-859.92,13.39) .. (-863.18,14.15)
 .. controls (-866.45,14.92) and (-867.12,13.96) .. (-871.54,15.21)
 .. controls (-875.95,16.46) and (-874.90,17.51) .. (-878.83,16.46)
 .. controls (-882.77,15.40) and (-882.58,15.21) .. (-886.51,14.63)
 .. controls (-890.45,14.06) and (-891.02,12.23) .. (-892.27,11.75)
 .. controls (-893.52,11.27) and (-893.81,10.02) .. (-897.07,9.54)
 .. controls (-900.34,9.06) and (-901.87,8.68) .. (-904.17,9.73)
 .. controls (-906.48,10.79) and (-906.09,10.31) .. (-907.34,11.85)
 .. controls (-908.59,13.38) and (-907.25,14.73) .. (-909.07,15.49)
 .. controls (-910.89,16.26) and (-910.99,16.93) .. (-914.16,16.84)
 .. controls (-917.33,16.74) and (-917.42,16.84) .. (-919.73,16.65)
 .. controls (-922.03,16.46) and (-920.78,15.78) .. (-926.44,16.36)
 .. controls (-932.11,16.94) and (-929.80,17.42) .. (-934.99,17.61)
 .. controls (-940.17,17.80) and (-940.75,18.28) .. (-944.88,17.61)
 .. controls (-949.00,16.94) and (-949.48,17.13) .. (-952.65,17.13)
 .. controls (-955.82,17.13) and (-951.21,18.38) .. (-957.16,17.04)
 .. controls (-963.12,15.69) and (-966.57,14.25) .. (-967.25,13.97)
),
1,((-967.25,13.97)
 .. controls (-967.25,13.97) and (-969.17,13.20) .. (-969.74,13.20)
 .. controls (-970.32,13.20) and (-972.53,13.58) .. (-973.58,13.97)
 .. controls (-974.64,14.35) and (-978.09,16.85) .. (-978.86,17.91)
 .. controls (-979.63,18.96) and (-983.56,21.08) .. (-985.68,20.40)
 .. controls (-987.79,19.73) and (-987.89,18.20) .. (-990.96,17.81)
 .. controls (-994.03,17.43) and (-1000.56,18.20) .. (-1002.48,18.20)
 .. controls (-1004.40,18.20) and (-1004.30,18.58) .. (-1007.66,18.58)
 .. controls (-1011.02,18.58) and (-1009.87,19.25) .. (-1013.90,18.77)
 .. controls (-1017.93,18.29) and (-1018.99,18.48) .. (-1020.33,18.77)
 .. controls (-1021.68,19.05) and (-1018.80,20.30) .. (-1023.60,19.53)
 .. controls (-1028.40,18.77) and (-1029.16,17.43) .. (-1032.52,18.20)
 .. controls (-1035.88,18.97) and (-1035.60,18.10) .. (-1039.92,18.49)
 .. controls (-1044.24,18.87) and (-1045.78,18.78) .. (-1047.22,18.78)
 .. controls (-1048.66,18.78) and (-1051.73,19.64) .. (-1052.31,19.45)
 .. controls (-1052.88,19.25) and (-1057.01,19.54) .. (-1059.51,19.44)
 .. controls (-1062.00,19.34) and (-1062.48,19.34) .. (-1066.32,19.82)
 .. controls (-1070.16,20.30) and (-1068.91,20.30) .. (-1072.37,20.20)
 .. controls (-1075.82,20.10) and (-1077.64,20.39) .. (-1079.18,21.07)
 .. controls (-1080.72,21.74) and (-1084.46,21.45) .. (-1086.38,21.26)
 .. controls (-1088.30,21.07) and (-1088.20,21.07) .. (-1089.36,20.88)
 .. controls (-1090.51,20.69) and (-1093.20,22.32) .. (-1093.20,22.32)
 .. controls (-1093.20,22.32) and (-1097.90,23.28) .. (-1098.38,23.57)
 .. controls (-1098.86,23.86) and (-1101.26,24.34) .. (-1101.26,24.34)
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__survey := "C4HelicopterHole";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1145.62,27.49)
 .. controls (-1145.62,27.49) and (-1145.33,27.40) .. (-1143.50,26.63)
 .. controls (-1141.68,25.86) and (-1142.64,26.54) .. (-1140.34,25.48)
 .. controls (-1138.03,24.42) and (-1137.74,23.18) .. (-1136.21,22.12)
 .. controls (-1134.67,21.07) and (-1134.48,20.78) .. (-1132.56,20.01)
 .. controls (-1130.64,19.24) and (-1125.65,16.65) .. (-1122.48,16.37)
 .. controls (-1119.31,16.08) and (-1118.83,16.94) .. (-1116.53,16.17)
 .. controls (-1114.22,15.41) and (-1114.32,15.12) .. (-1112.78,14.35)
 .. controls (-1111.25,13.58) and (-1111.53,13.39) .. (-1109.52,13.01)
 .. controls (-1107.50,12.63) and (-1108.65,12.43) .. (-1106.16,12.34)
 .. controls (-1103.66,12.24) and (-1105.39,11.76) .. (-1101.74,11.86)
 .. controls (-1098.09,11.96) and (-1101.26,11.38) .. (-1095.79,11.76)
 .. controls (-1090.32,12.15) and (-1091.95,13.20) .. (-1088.02,12.14)
 .. controls (-1084.08,11.09) and (-1081.20,11.08) .. (-1076.40,11.27)
 .. controls (-1071.60,11.46) and (-1072.56,12.52) .. (-1068.91,12.23)
 .. controls (-1065.26,11.95) and (-1066.61,12.72) .. (-1061.71,11.18)
 .. controls (-1056.81,9.65) and (-1056.91,8.69) .. (-1053.55,9.08)
 .. controls (-1050.19,9.46) and (-1051.05,10.04) .. (-1048.08,9.75)
 .. controls (-1045.10,9.47) and (-1046.73,10.33) .. (-1042.22,8.79)
 .. controls (-1037.71,7.25) and (-1038.58,7.25) .. (-1035.50,6.39)
 .. controls (-1032.43,5.52) and (-1031.57,5.14) .. (-1029.07,4.66)
 .. controls (-1026.57,4.18) and (-1027.06,4.27) .. (-1023.98,3.98)
 .. controls (-1020.91,3.69) and (-1021.29,3.02) .. (-1018.03,3.79)
 .. controls (-1014.76,4.56) and (-1016.68,4.94) .. (-1012.27,5.04)
 .. controls (-1007.85,5.14) and (-1008.43,5.04) .. (-1005.17,5.14)
 .. controls (-1001.90,5.24) and (-1002.19,5.14) .. (-998.64,5.33)
 .. controls (-995.09,5.53) and (-994.99,5.62) .. (-992.97,5.43)
 .. controls (-990.96,5.24) and (-994.80,4.57) .. (-988.66,4.37)
 .. controls (-982.51,4.18) and (-982.03,3.22) .. (-978.48,3.12)
 .. controls (-974.93,3.02) and (-975.50,3.22) .. (-974.16,3.02)
 .. controls (-972.82,2.83) and (-971.28,2.74) .. (-970.61,2.54)
 .. controls (-969.94,2.35) and (-969.17,2.64) .. (-968.88,1.77)
 .. controls (-968.59,0.91) and (-968.71,0.43) .. (-968.78,-0.24)
 .. controls (-968.98,-1.97) and (-970.03,-2.35) .. (-967.54,-2.74)
 .. controls (-965.04,-3.12) and (-965.90,-3.41) .. (-963.89,-3.51)
 .. controls (-961.87,-3.60) and (-963.98,-3.31) .. (-959.38,-3.70)
 .. controls (-954.77,-4.08) and (-956.88,-4.27) .. (-952.18,-4.37)
 .. controls (-947.47,-4.47) and (-950.16,-4.95) .. (-945.46,-4.47)
 .. controls (-940.75,-3.99) and (-942.00,-3.22) .. (-938.54,-3.70)
 .. controls (-935.09,-4.18) and (-936.62,-4.66) .. (-931.15,-4.09)
 .. controls (-925.68,-3.51) and (-918.77,-5.82) .. (-915.89,-5.53)
 .. controls (-913.01,-5.24) and (-912.53,-5.43) .. (-907.92,-4.95)
 .. controls (-903.31,-4.47) and (-901.49,-4.38) .. (-898.51,-4.28)
 .. controls (-895.53,-4.18) and (-894.48,-4.47) .. (-890.64,-4.57)
 .. controls (-886.80,-4.66) and (-887.57,-4.66) .. (-882.96,-4.37)
 .. controls (-878.35,-4.09) and (-877.30,-4.18) .. (-873.07,-3.80)
 .. controls (-868.85,-3.41) and (-870.48,-3.41) .. (-866.06,-3.41)
 .. controls (-861.65,-3.41) and (-861.94,-3.99) .. (-858.48,-4.09)
 .. controls (-855.02,-4.18) and (-856.66,-4.18) .. (-853.10,-4.18)
 .. controls (-849.55,-4.18) and (-848.40,-4.57) .. (-845.14,-4.37)
 .. controls (-841.87,-4.18) and (-841.49,-4.28) .. (-838.42,-4.66)
 .. controls (-835.34,-5.05) and (-835.73,-5.72) .. (-831.41,-5.14)
 .. controls (-827.09,-4.57) and (-827.18,-4.47) .. (-823.63,-4.76)
 .. controls (-820.08,-5.05) and (-819.31,-4.57) .. (-817.20,-4.67)
 .. controls (-815.09,-4.77) and (-816.05,-4.77) .. (-813.46,-5.15)
 .. controls (-810.87,-5.54) and (-811.35,-5.35) .. (-806.06,-5.15)
 .. controls (-800.78,-4.96) and (-801.17,-4.76) .. (-796.85,-5.05)
 .. controls (-792.53,-5.33) and (-793.49,-5.72) .. (-789.94,-5.33)
 .. controls (-786.38,-4.95) and (-787.44,-4.94) .. (-784.27,-4.94)
 .. controls (-781.11,-4.94) and (-783.60,-4.66) .. (-779.47,-5.14)
 .. controls (-775.35,-5.62) and (-775.15,-5.14) .. (-771.41,-6.10)
 .. controls (-767.67,-7.07) and (-767.28,-7.55) .. (-764.88,-8.22)
 .. controls (-762.48,-8.89) and (-763.16,-9.28) .. (-760.37,-8.99)
 .. controls (-757.59,-8.70) and (-757.30,-8.51) .. (-755.28,-8.70)
 .. controls (-753.27,-8.90) and (-755.28,-8.99) .. (-751.92,-9.47)
 .. controls (-748.56,-9.95) and (-748.95,-9.47) .. (-746.35,-10.43)
 .. controls (-743.76,-11.39) and (-744.63,-11.30) .. (-742.03,-12.26)
 .. controls (-739.44,-13.22) and (-740.88,-13.12) .. (-737.52,-13.98)
 .. controls (-734.16,-14.85) and (-734.83,-15.90) .. (-731.28,-14.94)
 .. controls (-727.73,-13.98) and (-729.17,-14.08) .. (-725.42,-13.89)
 .. controls (-721.68,-13.70) and (-722.35,-13.02) .. (-718.80,-13.69)
 .. controls (-715.25,-14.37) and (-715.92,-14.27) .. (-712.66,-14.37)
 .. controls (-709.39,-14.46) and (-709.01,-14.27) .. (-705.65,-14.75)
 .. controls (-702.29,-15.23) and (-701.90,-15.61) .. (-697.49,-15.71)
 .. controls (-693.07,-15.80) and (-694.51,-16.09) .. (-689.81,-15.61)
 .. controls (-685.10,-15.13) and (-678.38,-15.61) .. (-677.81,-15.99)
 .. controls (-677.23,-16.37) and (-678.00,-16.37) .. (-675.70,-16.37)
 .. controls (-673.39,-16.37) and (-674.16,-15.22) .. (-667.73,-15.99)
 .. controls (-661.30,-16.75) and (-663.79,-17.43) .. (-659.47,-16.66)
 .. controls (-655.15,-15.89) and (-657.75,-15.41) .. (-652.37,-15.32)
 .. controls (-646.99,-15.22) and (-648.91,-15.51) .. (-643.73,-15.32)
 .. controls (-638.55,-15.12) and (-640.85,-15.51) .. (-636.43,-14.64)
 .. controls (-632.02,-13.78) and (-633.36,-13.97) .. (-630.87,-13.78)
 .. controls (-628.37,-13.59) and (-629.52,-14.16) .. (-627.12,-13.30)
 .. controls (-624.72,-12.44) and (-625.39,-13.11) .. (-623.86,-11.96)
 .. controls (-622.32,-10.81) and (-623.95,-11.57) .. (-621.65,-10.52)
 .. controls (-619.35,-9.46) and (-620.50,-10.42) .. (-617.23,-8.79)
 .. controls (-613.97,-7.16) and (-614.74,-6.97) .. (-611.95,-6.30)
 .. controls (-609.17,-5.63) and (-610.71,-5.24) .. (-608.31,-5.44)
 .. controls (-605.91,-5.63) and (-606.10,-5.92) .. (-603.31,-5.72)
 .. controls (-600.53,-5.53) and (-600.33,-5.43) .. (-598.70,-5.81)
 .. controls (-597.07,-6.20) and (-594.77,-7.06) .. (-593.04,-7.35)
 .. controls (-591.31,-7.63) and (-591.22,-7.35) .. (-588.53,-8.21)
 .. controls (-585.84,-9.07) and (-586.03,-9.07) .. (-584.59,-9.65)
 .. controls (-583.15,-10.23) and (-583.44,-10.71) .. (-581.04,-10.99)
 .. controls (-578.64,-11.28) and (-578.35,-11.76) .. (-574.80,-11.28)
 .. controls (-571.25,-10.80) and (-572.98,-11.67) .. (-567.41,-10.61)
 .. controls (-561.84,-9.56) and (-562.99,-9.27) .. (-560.11,-9.36)
 .. controls (-557.23,-9.46) and (-557.71,-9.75) .. (-555.03,-9.75)
 .. controls (-552.34,-9.75) and (-553.11,-9.75) .. (-549.84,-9.65)
 .. controls (-546.58,-9.56) and (-546.96,-10.13) .. (-544.47,-10.04)
 .. controls (-541.97,-9.95) and (-541.78,-11.67) .. (-539.00,-12.44)
 .. controls (-536.21,-13.21) and (-534.77,-13.12) .. (-531.32,-13.51)
 .. controls (-527.86,-13.89) and (-526.13,-14.56) .. (-522.19,-15.13)
 .. controls (-518.26,-15.70) and (-521.04,-16.28) .. (-514.52,-16.19)
 .. controls (-507.99,-16.09) and (-505.59,-16.86) .. (-501.65,-16.96)
 .. controls (-497.72,-17.05) and (-498.29,-16.29) .. (-494.74,-16.77)
 .. controls (-491.19,-17.25) and (-491.00,-17.25) .. (-487.64,-16.96)
 .. controls (-484.28,-16.67) and (-485.81,-16.87) .. (-480.72,-16.58)
 .. controls (-475.64,-16.29) and (-478.13,-16.39) .. (-473.04,-16.58)
 .. controls (-467.96,-16.77) and (-470.36,-16.39) .. (-463.35,-16.96)
 .. controls (-456.34,-17.54) and (-456.05,-18.11) .. (-452.12,-17.63)
 .. controls (-448.18,-17.15) and (-445.59,-18.11) .. (-442.71,-18.11)
 .. controls (-439.83,-18.11) and (-439.35,-17.83) .. (-436.56,-18.11)
 .. controls (-433.78,-18.40) and (-434.74,-18.98) .. (-429.84,-19.36)
 .. controls (-424.95,-19.75) and (-425.81,-20.03) .. (-422.55,-19.55)
 .. controls (-419.28,-19.07) and (-422.16,-20.03) .. (-415.16,-19.94)
 .. controls (-408.15,-19.84) and (-408.44,-19.46) .. (-404.40,-19.55)
 .. controls (-400.37,-19.65) and (-399.80,-19.65) .. (-397.78,-19.75)
 .. controls (-395.76,-19.84) and (-393.65,-19.65) .. (-390.48,-19.84)
 .. controls (-387.31,-20.03) and (-381.36,-20.03) .. (-378.87,-19.93)
 .. controls (-376.37,-19.84) and (-377.72,-19.45) .. (-374.16,-19.64)
 .. controls (-370.61,-19.84) and (-372.92,-19.74) .. (-368.12,-20.22)
 .. controls (-363.32,-20.70) and (-364.57,-20.99) .. (-361.21,-21.19)
 .. controls (-357.85,-21.38) and (-355.64,-21.67) .. (-353.33,-21.28)
 .. controls (-351.03,-20.90) and (-350.26,-20.81) .. (-348.25,-21.00)
 .. controls (-346.23,-21.19) and (-345.75,-21.10) .. (-343.83,-20.90)
 .. controls (-341.91,-20.71) and (-343.83,-20.90) .. (-340.66,-20.52)
 .. controls (-337.49,-20.13) and (-339.80,-20.23) .. (-333.94,-19.56)
 .. controls (-328.08,-18.89) and (-329.62,-18.41) .. (-325.30,-18.89)
 .. controls (-320.98,-19.37) and (-319.64,-19.37) .. (-317.24,-19.56)
 .. controls (-314.84,-19.75) and (-307.92,-20.33) .. (-306.39,-20.52)
 .. controls (-304.85,-20.71) and (-300.72,-20.71) .. (-296.88,-21.29)
 .. controls (-293.04,-21.86) and (-287.09,-21.19) .. (-284.60,-20.81)
 .. controls (-282.10,-20.42) and (-282.48,-20.42) .. (-280.18,-20.52)
 .. controls (-277.88,-20.61) and (-278.07,-20.90) .. (-276.44,-20.80)
 .. controls (-274.80,-20.71) and (-272.12,-20.71) .. (-266.64,-20.13)
 .. controls (-261.17,-19.55) and (-258.20,-19.93) .. (-255.32,-20.32)
 .. controls (-252.44,-20.70) and (-251.87,-21.18) .. (-249.95,-20.70)
 .. controls (-248.03,-20.23) and (-250.91,-20.22) .. (-246.87,-19.94)
 .. controls (-242.84,-19.65) and (-245.63,-19.27) .. (-240.34,-19.56)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-240.34,-19.56)
 .. controls (-240.34,-19.56) and (-237.94,-20.23) .. (-235.54,-19.95)
 .. controls (-233.14,-19.66) and (-230.36,-20.42) .. (-228.34,-19.85)
 .. controls (-226.33,-19.27) and (-224.98,-18.98) .. (-222.29,-19.36)
 .. controls (-219.61,-19.75) and (-218.55,-19.46) .. (-215.38,-19.46)
 .. controls (-212.21,-19.46) and (-211.73,-19.65) .. (-210.77,-19.74)
 .. controls (-209.81,-19.84) and (-212.50,-20.03) .. (-207.99,-20.13)
 .. controls (-203.48,-20.22) and (-200.98,-20.60) .. (-198.29,-20.12)
 .. controls (-195.61,-19.64) and (-196.37,-19.07) .. (-193.11,-19.26)
 .. controls (-189.85,-19.45) and (-190.62,-19.64) .. (-188.12,-19.55)
 .. controls (-185.62,-19.45) and (-186.49,-19.36) .. (-183.80,-19.36)
 .. controls (-181.11,-19.36) and (-179.77,-18.97) .. (-176.02,-19.16)
 .. controls (-172.28,-19.36) and (-173.72,-19.55) .. (-170.74,-19.93)
 .. controls (-167.77,-20.32) and (-169.78,-19.74) .. (-164.89,-20.61)
 .. controls (-159.99,-21.47) and (-160.57,-22.14) .. (-157.02,-21.66)
 .. controls (-153.46,-21.18) and (-153.66,-21.37) .. (-149.72,-21.85)
 .. controls (-145.78,-22.33) and (-147.13,-21.66) .. (-144.63,-22.33)
 .. controls (-142.14,-23.01) and (-139.35,-22.62) .. (-137.43,-22.62)
 .. controls (-135.51,-22.62) and (-134.46,-23.01) .. (-131.29,-23.20)
 .. controls (-128.12,-23.39) and (-121.98,-23.87) .. (-119.96,-23.29)
 .. controls (-117.94,-22.72) and (-118.23,-22.43) .. (-116.12,-22.62)
 .. controls (-114.01,-22.81) and (-110.55,-22.33) .. (-107.86,-21.85)
 .. controls (-105.18,-21.37) and (-104.22,-21.76) .. (-101.72,-21.37)
 .. controls (-99.22,-20.99) and (-99.51,-20.99) .. (-98.36,-20.89)
 .. controls (-97.21,-20.80) and (-99.13,-21.18) .. (-96.54,-20.80)
 .. controls (-93.94,-20.41) and (-92.60,-20.80) .. (-90.20,-20.51)
 .. controls (-87.80,-20.22) and (-89.24,-20.22) .. (-86.84,-20.22)
 .. controls (-84.44,-20.22) and (-85.98,-20.22) .. (-82.71,-20.60)
 .. controls (-79.45,-20.99) and (-78.68,-21.85) .. (-75.99,-21.56)
 .. controls (-73.30,-21.28) and (-70.81,-20.80) .. (-68.79,-21.47)
 .. controls (-66.77,-22.14) and (-63.70,-22.24) .. (-61.49,-22.14)
 .. controls (-59.29,-22.04) and (-61.11,-21.66) .. (-58.71,-22.14)
 .. controls (-56.31,-22.62) and (-53.33,-22.62) .. (-50.93,-22.42)
 .. controls (-48.53,-22.23) and (-47.29,-22.61) .. (-44.12,-22.23)
 .. controls (-40.95,-21.84) and (-44.69,-22.52) .. (-40.18,-21.75)
 .. controls (-35.67,-20.98) and (-38.65,-20.41) .. (-34.33,-20.60)
 .. controls (-30.01,-20.79) and (-32.79,-20.89) .. (-29.05,-20.98)
 .. controls (-25.30,-21.08) and (-26.17,-20.89) .. (-23.19,-21.08)
 .. controls (-20.22,-21.27) and (-20.60,-21.27) .. (-16.57,-21.17)
 .. controls (-12.53,-21.08) and (-13.59,-22.23) .. (-10.23,-21.85)
 .. controls (-6.87,-21.46) and (-6.87,-21.85) .. (-3.61,-22.14)
 .. controls (-0.34,-22.42) and (0.91,-22.90) .. (2.54,-22.90)
 .. controls (4.17,-22.90) and (5.32,-23.19) .. (8.01,-22.90)
 .. controls (10.70,-22.62) and (9.93,-22.42) .. (12.04,-22.52)
 .. controls (14.15,-22.62) and (14.73,-22.62) .. (15.69,-22.71)
 .. controls (16.65,-22.81) and (15.31,-22.90) .. (17.23,-22.81)
 .. controls (19.15,-22.71) and (17.32,-23.58) .. (21.26,-22.61)
 .. controls (25.19,-21.65) and (29.03,-22.81) .. (30.67,-22.71)
 .. controls (32.30,-22.61) and (36.43,-22.81) .. (39.50,-23.00)
 .. controls (42.57,-23.19) and (40.46,-22.71) .. (44.30,-23.19)
 .. controls (48.14,-23.67) and (50.06,-24.72) .. (51.98,-24.34)
 .. controls (53.90,-23.96) and (52.36,-23.67) .. (56.30,-23.86)
 .. controls (60.23,-24.05) and (59.37,-23.67) .. (62.63,-23.76)
 .. controls (65.90,-23.86) and (65.99,-23.86) .. (68.20,-23.86)
 .. controls (70.41,-23.86) and (71.56,-23.96) .. (74.06,-24.34)
 .. controls (76.55,-24.73) and (75.11,-25.02) .. (77.99,-24.64)
 .. controls (80.87,-24.26) and (81.45,-25.51) .. (85.10,-24.83)
 .. controls (88.75,-24.16) and (86.44,-23.97) .. (89.42,-24.16)
 .. controls (92.39,-24.36) and (92.49,-24.55) .. (95.56,-24.16)
 .. controls (98.63,-23.78) and (99.50,-23.94) .. (101.71,-23.78)
 .. controls (104.30,-23.59) and (108.14,-22.82) .. (111.11,-22.72)
 .. controls (114.09,-22.63) and (113.03,-21.76) .. (116.68,-22.43)
 .. controls (120.33,-23.11) and (119.27,-23.30) .. (122.83,-23.39)
 .. controls (126.38,-23.49) and (124.07,-24.26) .. (128.01,-23.49)
 .. controls (131.94,-22.73) and (130.22,-22.25) .. (133.58,-22.73)
 .. controls (136.94,-23.21) and (137.22,-23.88) .. (139.05,-23.88)
 .. controls (140.87,-23.88) and (139.34,-24.74) .. (144.81,-24.74)
 .. controls (150.28,-24.74) and (148.65,-25.22) .. (151.82,-25.03)
 .. controls (154.98,-24.84) and (153.54,-24.93) .. (157.67,-24.65)
 .. controls (161.80,-24.36) and (162.09,-24.26) .. (165.06,-24.17)
 .. controls (168.04,-24.07) and (167.94,-24.26) .. (171.50,-24.26)
 .. controls (175.05,-24.26) and (174.09,-23.78) .. (177.16,-23.97)
 .. controls (180.23,-24.17) and (181.67,-24.64) .. (186.38,-24.26)
 .. controls (191.08,-23.88) and (188.58,-23.49) .. (193.29,-24.74)
 .. controls (197.99,-25.99) and (205.10,-25.32) .. (206.34,-25.03)
 .. controls (207.59,-24.74) and (207.88,-25.60) .. (211.82,-25.41)
 .. controls (215.75,-25.22) and (219.40,-25.51) .. (221.22,-25.89)
 .. controls (223.05,-26.27) and (223.72,-26.75) .. (225.35,-26.75)
 .. controls (226.98,-26.75) and (231.02,-25.70) .. (234.09,-26.08)
 .. controls (237.16,-26.47) and (239.37,-26.47) .. (241.10,-26.27)
 .. controls (242.82,-26.08) and (242.63,-26.47) .. (245.32,-26.08)
 .. controls (248.01,-25.70) and (249.83,-25.41) .. (250.60,-25.60)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((250.60,-25.60)
 .. controls (250.60,-25.60) and (251.37,-25.70) .. (255.88,-26.66)
 .. controls (260.39,-27.62) and (266.25,-28.00) .. (268.65,-27.62)
 .. controls (271.05,-27.23) and (277.00,-27.42) .. (279.50,-27.33)
 .. controls (281.99,-27.23) and (283.34,-26.56) .. (285.54,-26.46)
 .. controls (287.75,-26.36) and (286.70,-26.56) .. (288.33,-26.27)
 .. controls (289.96,-25.98) and (287.18,-26.17) .. (290.73,-25.60)
 .. controls (294.28,-25.02) and (294.95,-24.83) .. (297.06,-24.83)
 .. controls (299.18,-24.83) and (301.58,-25.11) .. (306.47,-25.40)
 .. controls (311.37,-25.69) and (313.19,-27.22) .. (316.46,-27.32)
 .. controls (319.72,-27.42) and (322.98,-27.32) .. (325.29,-27.32)
 .. controls (327.59,-27.32) and (325.58,-27.70) .. (330.18,-27.22)
 .. controls (334.79,-26.74) and (332.78,-27.03) .. (337.58,-26.36)
 .. controls (342.37,-25.68) and (342.57,-25.30) .. (345.73,-25.69)
 .. controls (348.90,-26.07) and (349.19,-25.97) .. (351.40,-25.88)
 .. controls (353.61,-25.78) and (352.45,-26.74) .. (357.06,-25.50)
 .. controls (361.67,-24.25) and (366.09,-24.54) .. (368.97,-23.96)
 .. controls (371.85,-23.39) and (374.05,-22.91) .. (376.93,-22.43)
 .. controls (379.81,-21.95) and (377.03,-21.95) .. (382.02,-21.66)
 .. controls (387.01,-21.38) and (389.41,-21.38) .. (390.66,-21.38)
 .. controls (391.91,-21.38) and (397.19,-21.57) .. (399.01,-21.76)
 .. controls (400.84,-21.95) and (402.18,-23.01) .. (404.97,-23.20)
 .. controls (407.75,-23.39) and (412.84,-24.06) .. (414.57,-24.06)
 .. controls (416.30,-24.06) and (419.75,-23.77) .. (422.25,-23.96)
 .. controls (424.74,-24.16) and (425.99,-23.10) .. (428.78,-23.10)
 .. controls (431.56,-23.10) and (433.38,-24.15) .. (435.40,-23.58)
 .. controls (437.41,-23.00) and (437.80,-22.52) .. (440.20,-22.52)
 .. controls (442.60,-22.52) and (447.78,-22.61) .. (449.89,-22.52)
 .. controls (452.01,-22.42) and (454.31,-21.85) .. (456.33,-21.85)
 .. controls (458.34,-21.85) and (459.01,-22.90) .. (461.70,-22.71)
 .. controls (464.39,-22.52) and (464.10,-22.42) .. (467.17,-22.71)
 .. controls (470.25,-23.00) and (473.32,-23.67) .. (475.14,-23.57)
 .. controls (476.97,-23.48) and (480.71,-24.63) .. (484.07,-24.44)
 .. controls (487.43,-24.24) and (490.50,-24.34) .. (491.46,-24.53)
 .. controls (492.42,-24.73) and (494.73,-25.01) .. (496.07,-25.21)
 .. controls (497.41,-25.40) and (502.98,-26.36) .. (506.54,-26.17)
 .. controls (510.09,-25.97) and (511.24,-26.55) .. (514.89,-26.07)
 .. controls (518.54,-25.59) and (517.96,-25.20) .. (521.61,-25.40)
 .. controls (525.26,-25.59) and (529.67,-26.07) .. (531.88,-25.88)
 .. controls (534.09,-25.69) and (533.22,-25.59) .. (537.74,-25.88)
 .. controls (542.25,-26.17) and (540.90,-26.07) .. (544.26,-26.07)
 .. controls (547.62,-26.07) and (548.01,-26.55) .. (552.33,-26.55)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((552.33,-26.55)
 .. controls (552.33,-26.55) and (555.30,-26.75) .. (556.94,-26.46)
 .. controls (558.57,-26.17) and (561.83,-25.79) .. (563.46,-25.59)
 .. controls (565.10,-25.40) and (568.36,-26.75) .. (570.09,-26.65)
 .. controls (571.82,-26.56) and (574.98,-27.13) .. (576.90,-27.23)
 .. controls (578.82,-27.32) and (580.07,-27.80) .. (583.24,-27.61)
 .. controls (586.41,-27.42) and (589.19,-26.56) .. (590.54,-26.37)
 .. controls (591.88,-26.17) and (596.17,-25.91) .. (597.64,-25.98)
 .. controls (603.78,-26.27) and (603.11,-26.27) .. (604.65,-26.27)
 .. controls (606.18,-26.27) and (606.95,-26.56) .. (608.58,-26.27)
 .. controls (610.22,-25.98) and (610.12,-26.08) .. (612.62,-25.89)
 .. controls (615.11,-25.70) and (612.81,-25.50) .. (616.17,-25.60)
 .. controls (619.53,-25.70) and (619.53,-26.08) .. (622.60,-25.60)
 .. controls (625.67,-25.12) and (625.58,-25.60) .. (629.90,-25.70)
 .. controls (634.22,-25.79) and (635.27,-25.60) .. (637.67,-25.22)
 .. controls (640.07,-24.83) and (645.64,-24.06) .. (646.41,-24.35)
 .. controls (647.18,-24.64) and (648.14,-24.93) .. (650.54,-25.31)
 .. controls (652.94,-25.70) and (654.66,-24.93) .. (655.62,-24.83)
 .. controls (656.58,-24.74) and (658.79,-24.74) .. (660.71,-24.83)
 .. controls (662.63,-24.93) and (662.92,-24.93) .. (664.65,-24.93)
 .. controls (666.38,-24.93) and (666.09,-24.64) .. (668.39,-24.93)
 .. controls (670.70,-25.22) and (671.08,-25.98) .. (672.81,-25.79)
 .. controls (674.54,-25.60) and (673.10,-25.31) .. (675.78,-25.41)
 .. controls (678.47,-25.50) and (678.57,-25.98) .. (681.16,-25.60)
 .. controls (683.75,-25.22) and (684.52,-25.70) .. (687.21,-25.50)
 .. controls (689.90,-25.31) and (688.46,-25.12) .. (692.01,-25.22)
 .. controls (695.56,-25.31) and (692.78,-24.93) .. (697.29,-25.41)
 .. controls (701.80,-25.89) and (702.57,-26.75) .. (705.06,-26.56)
 .. controls (707.56,-26.37) and (706.79,-26.66) .. (709.77,-26.47)
 .. controls (712.74,-26.27) and (714.47,-26.75) .. (715.82,-27.04)
 .. controls (717.16,-27.33) and (722.34,-27.91) .. (724.65,-28.10)
 .. controls (726.95,-28.29) and (734.34,-27.62) .. (736.07,-27.42)
 .. controls (737.80,-27.23) and (740.58,-28.10) .. (743.18,-27.71)
 .. controls (745.77,-27.33) and (745.29,-27.04) .. (747.98,-27.04)
 .. controls (750.66,-27.04) and (753.35,-27.13) .. (757.10,-27.33)
 .. controls (760.84,-27.52) and (761.42,-27.33) .. (762.66,-27.61)
 .. controls (763.91,-27.90) and (763.53,-28.29) .. (766.12,-28.48)
 .. controls (768.71,-28.67) and (767.66,-28.29) .. (771.21,-28.57)
 .. controls (774.76,-28.86) and (778.12,-29.63) .. (780.14,-29.43)
 .. controls (782.15,-29.24) and (786.86,-29.14) .. (789.06,-29.14)
 .. controls (791.27,-29.14) and (795.02,-30.20) .. (797.32,-30.01)
 .. controls (799.62,-29.81) and (802.12,-30.29) .. (804.23,-30.10)
 .. controls (806.34,-29.91) and (804.90,-30.00) .. (808.46,-29.81)
 .. controls (812.01,-29.62) and (812.30,-30.48) .. (815.85,-29.43)
 .. controls (819.40,-28.37) and (821.89,-28.56) .. (823.14,-28.37)
 .. controls (824.39,-28.18) and (824.77,-28.27) .. (826.12,-28.47)
 .. controls (827.46,-28.66) and (830.34,-28.75) .. (831.69,-28.66)
 .. controls (833.03,-28.56) and (833.61,-28.95) .. (836.77,-28.66)
 .. controls (839.94,-28.37) and (838.69,-27.99) .. (841.00,-28.28)
 .. controls (843.30,-28.56) and (848.68,-28.66) .. (850.98,-28.37)
 .. controls (853.29,-28.08) and (852.71,-27.51) .. (855.49,-27.89)
 .. controls (858.28,-28.28) and (861.16,-28.66) .. (861.64,-28.66)
 .. controls (862.12,-28.66) and (864.33,-28.95) .. (864.81,-28.95)
 .. controls (865.29,-28.95) and (867.21,-28.95) .. (869.03,-28.95)
 .. controls (870.85,-28.95) and (872.68,-29.14) .. (874.79,-28.76)
 .. controls (876.90,-28.37) and (877.38,-27.89) .. (881.99,-27.99)
 .. controls (886.60,-28.09) and (886.98,-29.05) .. (889.29,-28.57)
 .. controls (891.59,-28.09) and (890.92,-27.70) .. (894.47,-28.09)
 .. controls (898.02,-28.47) and (896.29,-29.14) .. (900.13,-28.86)
 .. controls (903.97,-28.57) and (901.77,-28.66) .. (906.47,-28.76)
 .. controls (911.17,-28.86) and (910.21,-28.86) .. (913.77,-28.38)
 .. controls (917.32,-27.90) and (917.61,-27.99) .. (919.72,-27.99)
 .. controls (921.83,-27.99) and (922.31,-28.09) .. (925.86,-28.09)
 .. controls (929.41,-28.09) and (931.24,-27.99) .. (933.64,-27.70)
 .. controls (936.04,-27.42) and (939.59,-27.13) .. (941.89,-26.74)
 .. controls (944.20,-26.36) and (942.37,-26.26) .. (945.93,-26.26)
 .. controls (949.48,-26.26) and (948.42,-25.88) .. (951.49,-26.07)
 .. controls (954.57,-26.26) and (953.32,-26.36) .. (957.16,-26.64)
 .. controls (961.00,-26.93) and (960.13,-26.84) .. (963.01,-26.93)
 .. controls (965.89,-27.03) and (965.61,-27.51) .. (968.49,-27.41)
 .. controls (971.37,-27.31) and (969.64,-27.02) .. (974.44,-27.22)
 .. controls (979.24,-27.41) and (978.28,-26.93) .. (982.79,-27.22)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((982.79,-27.22)
 .. controls (982.79,-27.22) and (984.81,-27.22) .. (986.15,-27.41)
 .. controls (987.49,-27.60) and (991.05,-27.99) .. (991.72,-27.51)
 .. controls (992.39,-27.03) and (996.33,-26.65) .. (998.63,-27.22)
 .. controls (1000.93,-27.80) and (1003.72,-27.51) .. (1006.69,-27.99)
 .. controls (1009.67,-28.48) and (1008.71,-28.76) .. (1010.92,-28.48)
 .. controls (1013.13,-28.19) and (1012.93,-28.57) .. (1014.86,-28.67)
 .. controls (1016.78,-28.76) and (1018.31,-29.34) .. (1019.56,-29.05)
 .. controls (1020.81,-28.76) and (1023.88,-28.66) .. (1027.24,-28.18)
 .. controls (1030.60,-27.70) and (1032.61,-27.61) .. (1033.00,-27.99)
 .. controls (1033.38,-28.37) and (1032.90,-28.76) .. (1034.92,-28.85)
 .. controls (1036.93,-28.95) and (1037.80,-28.37) .. (1037.99,-29.05)
 .. controls (1038.18,-29.72) and (1038.47,-29.91) .. (1038.28,-30.29)
 .. controls (1038.09,-30.68) and (1037.70,-30.58) .. (1037.61,-31.54)
 .. controls (1037.51,-32.50) and (1037.51,-33.17) .. (1037.99,-34.33)
 .. controls (1038.47,-35.48) and (1038.28,-36.25) .. (1039.24,-36.73)
 .. controls (1040.20,-37.21) and (1042.40,-38.17) .. (1043.75,-37.98)
 .. controls (1045.09,-37.79) and (1046.34,-37.79) .. (1046.82,-37.88)
 .. controls (1047.30,-37.98) and (1048.64,-38.46) .. (1048.93,-38.94)
 .. controls (1049.22,-39.42) and (1048.61,-38.96) .. (1049.51,-40.29)
 .. controls (1051.14,-42.69) and (1051.14,-42.21) .. (1051.53,-43.36)
 .. controls (1051.91,-44.51) and (1051.91,-44.51) .. (1052.29,-45.18)
 .. controls (1052.68,-45.86) and (1052.49,-46.91) .. (1053.16,-47.10)
 .. controls (1053.83,-47.30) and (1058.15,-47.39) .. (1059.69,-47.49)
 .. controls (1061.22,-47.58) and (1061.51,-47.77) .. (1062.86,-48.45)
 .. controls (1064.20,-49.12) and (1063.62,-48.54) .. (1066.41,-49.60)
 .. controls (1069.19,-50.65) and (1070.35,-51.04) .. (1072.36,-51.52)
 .. controls (1074.38,-51.99) and (1075.53,-52.57) .. (1078.61,-52.47)
 .. controls (1081.68,-52.37) and (1083.41,-52.47) .. (1085.13,-52.85)
 .. controls (1086.86,-53.24) and (1092.34,-53.90) .. (1094.45,-53.42)
 .. controls (1096.56,-52.94) and (1095.41,-53.13) .. (1099.44,-53.52)
 .. controls (1103.47,-53.90) and (1107.22,-55.24) .. (1110.67,-54.57)
 .. controls (1114.13,-53.90) and (1119.12,-53.80) .. (1122.58,-52.93)
 .. controls (1126.03,-52.07) and (1127.76,-51.97) .. (1129.49,-51.78)
 .. controls (1131.22,-51.59) and (1134.58,-51.40) .. (1135.63,-51.49)
 .. controls (1136.69,-51.59) and (1139.95,-51.68) .. (1141.20,-51.59)
 .. controls (1142.45,-51.49) and (1145.62,-51.68) .. (1145.62,-51.68)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1095.48,53.52)
 .. controls (1094.14,54.00) and (1093.57,53.71) .. (1092.80,53.90)
 .. controls (1092.03,54.09) and (1087.13,54.48) .. (1086.08,54.19)
 .. controls (1085.02,53.90) and (1078.11,53.13) .. (1074.66,53.42)
 .. controls (1071.20,53.71) and (1069.57,54.09) .. (1065.34,54.47)
 .. controls (1061.12,54.86) and (1060.64,53.99) .. (1059.11,54.47)
 .. controls (1057.57,54.95) and (1057.09,54.09) .. (1054.98,54.47)
 .. controls (1052.87,54.86) and (1053.06,55.24) .. (1049.12,54.67)
 .. controls (1045.19,54.09) and (1043.75,53.03) .. (1040.68,52.07)
 .. controls (1037.60,51.11) and (1036.16,50.15) .. (1036.16,50.15)
 .. controls (1036.16,50.15) and (1032.23,45.16) .. (1031.56,44.59)
 .. controls (1030.88,44.01) and (1031.17,43.34) .. (1029.54,41.51)
 .. controls (1027.91,39.69) and (1028.96,42.09) .. (1026.95,38.35)
 .. controls (1024.93,34.60) and (1023.59,31.34) .. (1022.63,29.80)
 .. controls (1021.67,28.27) and (1020.52,27.21) .. (1019.08,26.44)
 .. controls (1017.64,25.67) and (1012.07,20.11) .. (1010.92,19.34)
 .. controls (1009.77,18.57) and (1008.23,16.36) .. (1004.77,14.54)
 .. controls (1001.32,12.71) and (999.88,10.79) .. (996.81,9.74)
 .. controls (993.73,8.68) and (990.28,9.36) .. (985.96,9.55)
 .. controls (981.64,9.74) and (982.98,8.97) .. (978.18,9.55)
 .. controls (973.38,10.13) and (974.15,9.07) .. (969.16,9.65)
 .. controls (964.17,10.22) and (964.17,10.12) .. (960.04,9.93)
 .. controls (955.91,9.74) and (954.18,9.55) .. (953.12,9.45)
 .. controls (952.07,9.36) and (944.58,9.16) .. (942.95,9.16)
 .. controls (941.32,9.16) and (940.36,9.26) .. (932.96,8.97)
 .. controls (925.57,8.68) and (927.40,8.39) .. (922.31,8.39)
 .. controls (917.22,8.39) and (912.90,7.53) .. (910.21,8.01)
 .. controls (907.53,8.49) and (902.63,9.73) .. (899.46,9.45)
 .. controls (896.30,9.16) and (891.69,8.78) .. (888.52,8.58)
 .. controls (885.35,8.39) and (884.49,7.82) .. (880.84,7.82)
 .. controls (877.19,7.82) and (875.08,6.19) .. (871.82,7.43)
 .. controls (868.55,8.68) and (870.76,8.01) .. (866.63,9.74)
 .. controls (862.50,11.47) and (860.10,12.91) .. (858.76,13.29)
 .. controls (857.42,13.68) and (856.55,14.16) .. (855.11,14.16)
 .. controls (853.67,14.16) and (853.58,15.02) .. (851.75,14.54)
 .. controls (849.93,14.06) and (850.02,14.44) .. (848.58,13.58)
 .. controls (847.14,12.72) and (845.13,11.18) .. (843.50,10.12)
 .. controls (841.86,9.07) and (840.52,7.44) .. (838.50,6.19)
 .. controls (836.49,4.94) and (836.01,3.41) .. (833.99,2.73)
 .. controls (831.97,2.06) and (831.69,1.77) .. (830.05,1.39)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((830.05,1.39)
 .. controls (830.05,1.39) and (827.17,1.01) .. (825.54,1.87)
 .. controls (823.91,2.73) and (822.47,2.93) .. (819.59,4.56)
 .. controls (816.71,6.19) and (812.49,8.40) .. (810.09,9.07)
 .. controls (807.68,9.74) and (807.40,10.51) .. (802.98,10.80)
 .. controls (798.56,11.08) and (796.64,11.75) .. (794.24,12.14)
 .. controls (791.84,12.52) and (794.15,12.71) .. (788.96,12.52)
 .. controls (783.78,12.33) and (782.15,11.08) .. (779.65,11.46)
 .. controls (777.15,11.84) and (779.07,12.33) .. (775.23,11.94)
 .. controls (771.39,11.56) and (771.01,11.27) .. (768.99,11.27)
 .. controls (766.98,11.27) and (761.89,11.36) .. (759.11,11.94)
 .. controls (756.32,12.51) and (751.72,14.43) .. (746.15,13.95)
 .. controls (740.58,13.47) and (740.29,13.28) .. (737.32,13.28)
 .. controls (734.34,13.28) and (737.32,14.62) .. (730.41,13.37)
 .. controls (723.49,12.13) and (726.85,12.32) .. (721.86,11.55)
 .. controls (716.87,10.78) and (716.49,11.55) .. (711.88,9.44)
 .. controls (707.27,7.33) and (704.10,5.89) .. (702.38,5.41)
 .. controls (700.65,4.93) and (700.94,5.31) .. (696.90,4.16)
 .. controls (692.87,3.01) and (692.49,3.49) .. (688.94,2.05)
 .. controls (685.39,0.61) and (683.85,0.03) .. (682.31,-0.54)
 .. controls (680.78,-1.12) and (679.05,-0.06) .. (675.21,-1.22)
 .. controls (671.37,-2.37) and (669.35,-3.04) .. (667.43,-3.52)
 .. controls (665.51,-4.00) and (663.21,-5.44) .. (658.60,-5.92)
 .. controls (653.99,-6.40) and (655.34,-6.30) .. (651.21,-6.78)
 .. controls (647.08,-7.26) and (646.70,-7.74) .. (641.90,-8.61)
 .. controls (637.10,-9.47) and (637.19,-10.05) .. (632.20,-9.85)
 .. controls (627.21,-9.66) and (628.46,-8.42) .. (623.66,-9.28)
 .. controls (618.86,-10.14) and (619.82,-9.95) .. (615.40,-10.34)
 .. controls (610.98,-10.72) and (613.77,-10.43) .. (608.68,-11.30)
 .. controls (603.59,-12.16) and (602.15,-11.58) .. (600.81,-12.16)
 .. controls (599.46,-12.73) and (595.82,-14.46) .. (592.26,-14.46)
 .. controls (588.71,-14.46) and (586.03,-14.08) .. (581.61,-14.75)
 .. controls (577.19,-15.42) and (577.67,-16.00) .. (573.54,-16.19)
 .. controls (569.42,-16.38) and (571.43,-15.61) .. (565.77,-16.19)
 .. controls (560.10,-16.76) and (561.74,-17.05) .. (557.51,-16.19)
 .. controls (553.29,-15.32) and (556.07,-15.61) .. (548.97,-14.46)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((548.97,-14.46)
 .. controls (548.97,-14.46) and (547.53,-15.13) .. (546.28,-14.94)
 .. controls (545.03,-14.74) and (540.81,-13.50) .. (538.02,-12.82)
 .. controls (535.24,-12.15) and (531.02,-11.57) .. (528.62,-11.38)
 .. controls (526.22,-11.19) and (522.86,-10.42) .. (516.14,-9.94)
 .. controls (509.42,-9.46) and (510.47,-9.94) .. (507.88,-9.56)
 .. controls (505.29,-9.17) and (502.98,-8.88) .. (499.24,-8.12)
 .. controls (495.50,-7.35) and (494.82,-7.54) .. (491.75,-6.58)
 .. controls (488.68,-5.62) and (487.91,-5.52) .. (485.51,-4.37)
 .. controls (483.11,-3.22) and (486.95,-5.24) .. (480.52,-1.78)
 .. controls (474.09,1.68) and (470.44,2.06) .. (468.52,2.92)
 .. controls (466.60,3.79) and (461.51,3.98) .. (460.74,3.98)
 .. controls (459.97,3.98) and (455.27,1.58) .. (454.21,1.19)
 .. controls (453.16,0.81) and (446.82,-0.34) .. (444.90,-0.44)
 .. controls (442.98,-0.53) and (436.83,0.71) .. (433.38,0.61)
 .. controls (429.92,0.52) and (430.79,1.09) .. (427.14,0.23)
 .. controls (423.49,-0.64) and (425.03,-1.02) .. (420.03,-1.40)
 .. controls (415.04,-1.79) and (411.88,-2.66) .. (409.09,-2.56)
 .. controls (406.31,-2.47) and (407.27,-3.04) .. (404.39,-2.37)
 .. controls (401.51,-1.70) and (402.37,-3.14) .. (399.01,-1.70)
 .. controls (395.65,-0.26) and (396.52,-0.16) .. (394.50,0.03)
 .. controls (392.49,0.22) and (385.58,1.66) .. (385.58,1.66)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((385.58,1.66)
 .. controls (385.58,1.66) and (384.90,1.09) .. (382.70,0.89)
 .. controls (380.49,0.70) and (378.76,0.32) .. (374.73,1.09)
 .. controls (370.70,1.86) and (371.66,2.05) .. (366.38,1.67)
 .. controls (361.10,1.29) and (360.33,0.13) .. (356.68,0.04)
 .. controls (353.03,-0.05) and (354.66,-0.06) .. (349.00,0.62)
 .. controls (343.34,1.29) and (336.42,1.67) .. (334.02,2.54)
 .. controls (331.62,3.40) and (332.78,3.11) .. (327.11,3.31)
 .. controls (321.45,3.50) and (320.58,2.44) .. (316.74,2.92)
 .. controls (312.90,3.40) and (311.08,4.84) .. (307.04,4.45)
 .. controls (303.01,4.07) and (298.31,3.40) .. (298.31,3.40)
 .. controls (298.31,3.40) and (292.45,2.63) .. (290.34,2.24)
 .. controls (288.23,1.86) and (284.10,2.34) .. (281.22,2.53)
 .. controls (278.34,2.72) and (275.27,2.82) .. (271.14,2.62)
 .. controls (267.01,2.43) and (265.19,1.66) .. (262.31,1.38)
 .. controls (259.43,1.09) and (259.72,0.51) .. (256.45,0.41)
 .. controls (253.19,0.32) and (254.25,0.22) .. (249.06,0.51)
 .. controls (243.88,0.80) and (246.66,0.22) .. (240.04,1.18)
 .. controls (233.41,2.14) and (233.70,2.62) .. (228.81,2.62)
 .. controls (223.91,2.62) and (225.54,2.81) .. (220.55,2.24)
 .. controls (215.56,1.66) and (212.01,1.85) .. (209.61,1.37)
 .. controls (207.21,0.89) and (203.94,-0.55) .. (201.64,-0.84)
 .. controls (199.34,-1.12) and (194.15,-0.55) .. (190.02,-0.74)
 .. controls (185.90,-0.93) and (188.78,-1.12) .. (182.73,-1.22)
 .. controls (176.68,-1.32) and (178.12,-1.03) .. (170.73,-1.12)
 .. controls (163.34,-1.22) and (164.68,-1.03) .. (159.40,-0.64)
 .. controls (154.12,-0.26) and (157.96,-0.74) .. (149.61,0.60)
 .. controls (141.26,1.95) and (143.37,1.66) .. (140.01,1.47)
 .. controls (136.65,1.28) and (134.15,1.66) .. (131.18,1.66)
 .. controls (128.20,1.66) and (126.28,2.14) .. (124.36,1.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((124.36,1.85)
 .. controls (124.36,1.85) and (121.67,1.37) .. (119.18,0.99)
 .. controls (116.68,0.60) and (113.61,1.08) .. (110.25,1.18)
 .. controls (106.89,1.28) and (106.41,1.57) .. (102.57,1.95)
 .. controls (98.73,2.33) and (98.73,2.81) .. (94.60,3.01)
 .. controls (90.47,3.20) and (90.86,2.91) .. (86.44,3.01)
 .. controls (82.02,3.11) and (81.74,2.72) .. (77.70,2.44)
 .. controls (73.67,2.15) and (75.30,1.29) .. (67.05,1.29)
 .. controls (58.79,1.29) and (58.02,2.44) .. (54.86,1.96)
 .. controls (51.69,1.48) and (52.36,1.48) .. (48.62,1.10)
 .. controls (44.87,0.72) and (36.33,2.44) .. (32.78,2.15)
 .. controls (29.22,1.87) and (27.98,1.58) .. (24.42,1.58)
 .. controls (20.87,1.58) and (19.62,1.10) .. (13.77,1.00)
 .. controls (7.91,0.90) and (9.16,0.71) .. (4.84,0.04)
 .. controls (0.52,-0.63) and (2.73,-0.92) .. (-3.22,-0.54)
 .. controls (-9.17,-0.15) and (-8.60,-0.82) .. (-14.07,-0.05)
 .. controls (-19.54,0.71) and (-18.01,1.58) .. (-21.46,0.91)
 .. controls (-24.92,0.24) and (-32.70,-0.72) .. (-34.04,-0.72)
 .. controls (-35.38,-0.72) and (-35.19,-0.92) .. (-36.92,-0.72)
 .. controls (-38.65,-0.53) and (-45.08,0.14) .. (-47.87,-0.44)
 .. controls (-50.65,-1.01) and (-53.72,-1.59) .. (-56.03,-2.55)
 .. controls (-58.33,-3.51) and (-59.29,-4.47) .. (-62.17,-6.01)
 .. controls (-65.05,-7.55) and (-66.01,-9.47) .. (-67.55,-10.62)
 .. controls (-69.08,-11.77) and (-68.70,-12.35) .. (-70.14,-12.54)
 .. controls (-71.58,-12.73) and (-71.77,-13.40) .. (-74.94,-13.69)
 .. controls (-78.10,-13.98) and (-80.98,-14.84) .. (-83.19,-14.27)
 .. controls (-85.40,-13.69) and (-85.02,-13.69) .. (-89.24,-12.92)
 .. controls (-93.46,-12.16) and (-92.12,-11.87) .. (-96.92,-11.48)
 .. controls (-101.72,-11.10) and (-102.01,-10.14) .. (-105.37,-10.05)
 .. controls (-108.73,-9.95) and (-111.32,-9.37) .. (-112.76,-9.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-112.76,-9.85)
 .. controls (-112.76,-9.85) and (-116.12,-11.58) .. (-119.10,-11.77)
 .. controls (-122.07,-11.97) and (-123.13,-11.68) .. (-126.97,-11.68)
 .. controls (-130.81,-11.68) and (-135.61,-12.83) .. (-139.26,-11.87)
 .. controls (-142.90,-10.91) and (-142.42,-10.05) .. (-145.50,-11.01)
 .. controls (-148.57,-11.97) and (-150.58,-11.29) .. (-155.86,-12.93)
 .. controls (-161.14,-14.56) and (-162.30,-15.04) .. (-165.37,-14.56)
 .. controls (-168.44,-14.08) and (-165.85,-14.46) .. (-169.78,-13.50)
 .. controls (-173.72,-12.54) and (-175.16,-12.92) .. (-176.79,-11.20)
 .. controls (-178.42,-9.47) and (-180.73,-6.97) .. (-181.69,-5.34)
 .. controls (-182.65,-3.71) and (-182.74,-4.19) .. (-183.90,-1.98)
 .. controls (-185.05,0.23) and (-186.49,3.40) .. (-187.35,4.64)
 .. controls (-188.22,5.89) and (-188.79,6.28) .. (-190.23,6.85)
 .. controls (-191.67,7.43) and (-190.62,7.72) .. (-192.44,7.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-192.44,7.62)
 .. controls (-192.44,7.62) and (-201.08,9.25) .. (-203.77,8.00)
 .. controls (-206.46,6.75) and (-206.75,5.98) .. (-209.24,4.93)
 .. controls (-211.74,3.87) and (-210.78,4.35) .. (-213.27,2.91)
 .. controls (-215.77,1.47) and (-217.59,1.95) .. (-219.70,1.95)
 .. controls (-221.82,1.94) and (-226.23,2.04) .. (-228.05,4.63)
 .. controls (-229.88,7.22) and (-232.56,10.68) .. (-233.14,11.83)
 .. controls (-233.72,12.99) and (-234.39,18.84) .. (-236.31,21.25)
 .. controls (-238.23,23.65) and (-241.21,27.39) .. (-242.07,28.06)
 .. controls (-242.93,28.74) and (-244.57,31.14) .. (-246.39,30.46)
 .. controls (-248.21,29.79) and (-247.83,29.98) .. (-251.00,28.16)
 .. controls (-254.16,26.34) and (-254.74,26.63) .. (-256.95,24.03)
 .. controls (-259.16,21.44) and (-262.23,15.68) .. (-262.90,15.11)
 .. controls (-263.57,14.53) and (-268.76,9.73) .. (-269.53,8.96)
 .. controls (-270.29,8.20) and (-272.41,3.97) .. (-274.42,3.11)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-274.42,3.11)
 .. controls (-274.42,3.11) and (-274.23,3.11) .. (-277.11,1.76)
 .. controls (-279.99,0.41) and (-283.35,-1.03) .. (-287.10,-1.32)
 .. controls (-290.84,-1.61) and (-291.03,-3.05) .. (-293.72,-2.28)
 .. controls (-296.41,-1.51) and (-297.94,-2.09) .. (-299.57,-0.26)
 .. controls (-301.21,1.56) and (-303.99,4.83) .. (-304.76,6.07)
 .. controls (-305.53,7.32) and (-305.53,7.90) .. (-306.58,8.67)
 .. controls (-307.64,9.43) and (-309.17,10.30) .. (-312.24,9.43)
 .. controls (-315.32,8.57) and (-317.43,7.99) .. (-318.77,7.23)
 .. controls (-320.12,6.46) and (-321.84,4.44) .. (-322.90,3.67)
 .. controls (-323.96,2.91) and (-326.74,0.03) .. (-328.28,-1.61)
 .. controls (-329.81,-3.24) and (-331.35,-5.06) .. (-333.08,-5.26)
 .. controls (-334.80,-5.45) and (-338.83,-4.30) .. (-339.51,-3.62)
 .. controls (-340.18,-2.95) and (-340.27,-2.09) .. (-342.67,-1.03)
 .. controls (-345.07,0.03) and (-345.46,0.31) .. (-347.47,0.89)
 .. controls (-349.49,1.47) and (-352.27,2.81) .. (-353.52,3.01)
 .. controls (-354.77,3.20) and (-358.99,3.87) .. (-360.63,4.64)
 .. controls (-362.26,5.41) and (-364.37,6.27) .. (-366.39,6.18)
 .. controls (-368.40,6.08) and (-368.21,5.41) .. (-371.19,3.97)
 .. controls (-374.16,2.53) and (-373.97,1.86) .. (-376.56,1.00)
 .. controls (-379.16,0.13) and (-379.06,-0.64) .. (-382.42,-1.02)
 .. controls (-385.78,-1.41) and (-389.14,-2.27) .. (-392.02,-1.79)
 .. controls (-394.90,-1.31) and (-394.42,-0.93) .. (-396.63,-0.55)
 .. controls (-398.84,-0.16) and (-402.97,1.47) .. (-406.13,0.41)
 .. controls (-409.30,-0.64) and (-407.96,-0.45) .. (-410.74,-1.12)
 .. controls (-413.52,-1.80) and (-416.12,-1.51) .. (-420.44,-2.27)
 .. controls (-424.76,-3.04) and (-425.62,-3.23) .. (-429.08,-3.43)
 .. controls (-432.53,-3.62) and (-441.27,-4.29) .. (-443.09,-4.10)
 .. controls (-444.92,-3.91) and (-447.32,-3.71) .. (-451.44,-3.62)
 .. controls (-455.57,-3.52) and (-456.44,-2.75) .. (-459.89,-2.47)
 .. controls (-463.35,-2.18) and (-466.90,-2.18) .. (-469.20,-2.18)
 .. controls (-471.51,-2.18) and (-476.88,-3.23) .. (-480.72,-3.04)
 .. controls (-484.56,-2.85) and (-484.18,-2.75) .. (-486.29,-3.14)
 .. controls (-488.40,-3.52) and (-494.64,-5.44) .. (-496.18,-5.53)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-496.18,-5.53)
 .. controls (-496.18,-5.53) and (-498.58,-6.59) .. (-500.50,-6.59)
 .. controls (-502.42,-6.59) and (-504.63,-5.44) .. (-506.83,-4.28)
 .. controls (-509.04,-3.13) and (-509.43,-2.65) .. (-511.06,-0.34)
 .. controls (-512.69,1.96) and (-513.08,1.19) .. (-514.23,4.07)
 .. controls (-515.38,6.95) and (-515.29,6.37) .. (-516.25,8.77)
 .. controls (-517.20,11.17) and (-517.11,15.30) .. (-518.93,15.20)
 .. controls (-520.76,15.11) and (-522.87,14.92) .. (-524.12,14.05)
 .. controls (-525.36,13.19) and (-527.76,10.50) .. (-528.92,10.12)
 .. controls (-530.07,9.73) and (-529.49,8.29) .. (-532.08,8.96)
 .. controls (-534.67,9.64) and (-534.87,9.16) .. (-535.54,10.02)
 .. controls (-536.21,10.88) and (-536.40,11.17) .. (-537.94,12.42)
 .. controls (-539.47,13.67) and (-540.82,14.82) .. (-541.78,15.59)
 .. controls (-542.74,16.36) and (-544.37,17.90) .. (-544.85,18.28)
 .. controls (-545.33,18.67) and (-548.59,20.59) .. (-549.36,21.26)
 .. controls (-550.13,21.93) and (-551.66,22.89) .. (-552.62,23.37)
 .. controls (-553.58,23.85) and (-558.29,25.87) .. (-560.59,25.78)
 .. controls (-562.90,25.68) and (-563.28,26.07) .. (-565.88,24.82)
 .. controls (-568.47,23.57) and (-579.70,20.69) .. (-581.43,20.21)
 .. controls (-583.16,19.73) and (-586.52,17.81) .. (-590.08,17.72)
 .. controls (-593.63,17.62) and (-591.32,16.95) .. (-594.59,17.71)
 .. controls (-597.86,18.48) and (-600.74,20.11) .. (-601.70,21.07)
 .. controls (-602.66,22.03) and (-603.14,22.31) .. (-604.48,24.14)
 .. controls (-605.83,25.96) and (-606.79,28.17) .. (-608.23,28.26)
 .. controls (-609.67,28.36) and (-613.41,27.01) .. (-614.95,26.24)
 .. controls (-616.49,25.47) and (-616.49,26.34) .. (-617.92,24.32)
 .. controls (-619.36,22.30) and (-620.99,21.06) .. (-622.62,19.23)
 .. controls (-624.25,17.41) and (-625.40,15.30) .. (-625.98,14.72)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-625.98,14.72)
 .. controls (-625.98,14.72) and (-627.22,13.66) .. (-628.18,12.51)
 .. controls (-629.14,11.36) and (-633.74,6.76) .. (-636.43,5.61)
 .. controls (-639.12,4.46) and (-640.85,3.50) .. (-643.15,3.31)
 .. controls (-645.46,3.12) and (-649.59,1.29) .. (-651.22,0.72)
 .. controls (-652.85,0.14) and (-653.43,-1.20) .. (-656.88,-1.01)
 .. controls (-660.34,-0.82) and (-659.47,-1.11) .. (-662.55,-1.20)
 .. controls (-665.62,-1.30) and (-669.36,-1.78) .. (-673.01,-1.78)
 .. controls (-676.66,-1.78) and (-674.07,-2.74) .. (-680.11,-2.36)
 .. controls (-686.16,-1.98) and (-684.15,-1.98) .. (-688.66,-1.40)
 .. controls (-693.17,-0.83) and (-696.43,-1.31) .. (-699.41,-0.73)
 .. controls (-702.39,-0.16) and (-706.13,-0.35) .. (-709.39,0.23)
 .. controls (-712.66,0.80) and (-711.70,0.99) .. (-714.87,0.71)
 .. controls (-718.03,0.42) and (-715.54,-0.45) .. (-720.24,0.42)
 .. controls (-724.95,1.28) and (-723.89,1.09) .. (-727.83,2.05)
 .. controls (-731.76,3.01) and (-732.91,3.01) .. (-735.31,3.68)
 .. controls (-737.71,4.35) and (-735.02,1.63) .. (-741.07,5.98)
 .. controls (-748.94,11.65) and (-751.82,15.10) .. (-753.07,15.49)
 .. controls (-754.32,15.87) and (-755.28,16.16) .. (-756.43,16.45)
 .. controls (-757.58,16.74) and (-763.82,13.48) .. (-765.07,13.00)
 .. controls (-766.32,12.52) and (-767.95,11.37) .. (-769.68,10.70)
 .. controls (-771.41,10.03) and (-769.87,9.74) .. (-774.00,9.16)
 .. controls (-778.13,8.59) and (-777.84,8.78) .. (-779.57,8.21)
 .. controls (-781.30,7.63) and (-779.18,8.40) .. (-782.55,7.92)
 .. controls (-785.91,7.44) and (-785.04,7.82) .. (-787.54,7.44)
 .. controls (-790.04,7.05) and (-789.07,6.38) .. (-791.00,7.24)
 .. controls (-792.92,8.11) and (-789.65,7.34) .. (-795.03,8.49)
 .. controls (-800.40,9.63) and (-798.68,9.16) .. (-802.04,9.54)
 .. controls (-805.40,9.92) and (-803.09,8.96) .. (-807.03,10.59)
 .. controls (-810.96,12.22) and (-808.56,11.46) .. (-811.92,12.70)
 .. controls (-815.28,13.95) and (-815.47,14.91) .. (-818.26,14.82)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-818.26,14.82)
 .. controls (-818.26,14.82) and (-815.86,15.49) .. (-819.79,14.43)
 .. controls (-823.73,13.38) and (-820.18,14.24) .. (-824.59,13.48)
 .. controls (-829.01,12.71) and (-834.86,12.52) .. (-837.17,12.14)
 .. controls (-839.47,11.75) and (-836.78,12.04) .. (-841.49,11.75)
 .. controls (-846.19,11.47) and (-847.53,11.18) .. (-850.80,11.75)
 .. controls (-854.06,12.33) and (-852.82,12.23) .. (-856.56,12.52)
 .. controls (-860.30,12.81) and (-859.92,13.39) .. (-863.18,14.15)
 .. controls (-866.45,14.92) and (-867.12,13.96) .. (-871.54,15.21)
 .. controls (-875.95,16.46) and (-874.90,17.51) .. (-878.83,16.46)
 .. controls (-882.77,15.40) and (-882.58,15.21) .. (-886.51,14.63)
 .. controls (-890.45,14.06) and (-891.02,12.23) .. (-892.27,11.75)
 .. controls (-893.52,11.27) and (-893.81,10.02) .. (-897.07,9.54)
 .. controls (-900.34,9.06) and (-901.87,8.68) .. (-904.17,9.73)
 .. controls (-906.48,10.79) and (-906.09,10.31) .. (-907.34,11.85)
 .. controls (-908.59,13.38) and (-907.25,14.73) .. (-909.07,15.49)
 .. controls (-910.89,16.26) and (-910.99,16.93) .. (-914.16,16.84)
 .. controls (-917.33,16.74) and (-917.42,16.84) .. (-919.73,16.65)
 .. controls (-922.03,16.46) and (-920.78,15.78) .. (-926.44,16.36)
 .. controls (-932.11,16.94) and (-929.80,17.42) .. (-934.99,17.61)
 .. controls (-940.17,17.80) and (-940.75,18.28) .. (-944.88,17.61)
 .. controls (-949.00,16.94) and (-949.48,17.13) .. (-952.65,17.13)
 .. controls (-955.82,17.13) and (-951.21,18.38) .. (-957.16,17.04)
 .. controls (-963.12,15.69) and (-966.57,14.25) .. (-967.25,13.97)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-967.25,13.97)
 .. controls (-967.25,13.97) and (-969.17,13.20) .. (-969.74,13.20)
 .. controls (-970.32,13.20) and (-972.53,13.58) .. (-973.58,13.97)
 .. controls (-974.64,14.35) and (-978.09,16.85) .. (-978.86,17.91)
 .. controls (-979.63,18.96) and (-983.56,21.08) .. (-985.68,20.40)
 .. controls (-987.79,19.73) and (-987.89,18.20) .. (-990.96,17.81)
 .. controls (-994.03,17.43) and (-1000.56,18.20) .. (-1002.48,18.20)
 .. controls (-1004.40,18.20) and (-1004.30,18.58) .. (-1007.66,18.58)
 .. controls (-1011.02,18.58) and (-1009.87,19.25) .. (-1013.90,18.77)
 .. controls (-1017.93,18.29) and (-1018.99,18.48) .. (-1020.33,18.77)
 .. controls (-1021.68,19.05) and (-1018.80,20.30) .. (-1023.60,19.53)
 .. controls (-1028.40,18.77) and (-1029.16,17.43) .. (-1032.52,18.20)
 .. controls (-1035.88,18.97) and (-1035.60,18.10) .. (-1039.92,18.49)
 .. controls (-1044.24,18.87) and (-1045.78,18.78) .. (-1047.22,18.78)
 .. controls (-1048.66,18.78) and (-1051.73,19.64) .. (-1052.31,19.45)
 .. controls (-1052.88,19.25) and (-1057.01,19.54) .. (-1059.51,19.44)
 .. controls (-1062.00,19.34) and (-1062.48,19.34) .. (-1066.32,19.82)
 .. controls (-1070.16,20.30) and (-1068.91,20.30) .. (-1072.37,20.20)
 .. controls (-1075.82,20.10) and (-1077.64,20.39) .. (-1079.18,21.07)
 .. controls (-1080.72,21.74) and (-1084.46,21.45) .. (-1086.38,21.26)
 .. controls (-1088.30,21.07) and (-1088.20,21.07) .. (-1089.36,20.88)
 .. controls (-1090.51,20.69) and (-1093.20,22.32) .. (-1093.20,22.32)
 .. controls (-1093.20,22.32) and (-1097.90,23.28) .. (-1098.38,23.57)
 .. controls (-1098.86,23.86) and (-1101.26,24.34) .. (-1101.26,24.34)
));
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1136.46,24.68),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1095.80,13.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1073.67,13.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1044.99,11.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1021.93,9.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1001.34,6.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-969.85,5.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-946.42,-3.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-909.56,-3.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-883.70,-0.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-838.64,-3.40),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-806.30,-3.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-783.88,-3.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-761.14,-4.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-729.17,-7.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-665.37,-13.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-628.20,-10.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-603.75,-2.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-600.93,-1.72),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-583.35,-2.93),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-550.50,-5.27),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-529.31,-10.24),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-519.35,-10.41),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-483.28,-16.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-412.56,-16.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-398.90,-16.17),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-375.63,-15.44),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-344.89,-19.21),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-313.97,-17.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-284.31,-18.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-257.82,-11.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-236.34,-14.81),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-195.75,-16.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-145.66,-20.73),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-66.44,-20.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-46.56,-17.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((4.13,-21.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((55.32,-21.82),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((97.88,-20.95),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((132.05,-22.13),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((154.73,-19.59),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((223.43,-24.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((265.91,-21.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((341.82,-23.20),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((399.19,-20.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((429.60,-18.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((460.91,-20.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((522.36,-24.51),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((600.17,-23.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((656.26,-23.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((717.58,-25.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((768.03,-26.00),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((819.50,-27.23),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((839.67,-27.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((899.24,-27.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((943.77,-24.64),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((971.90,-25.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1011.42,-26.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1033.82,-27.04),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1058.24,-35.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1087.63,-34.24),1,0,"");
endfig;
current_scrap := "C4HelicopterHoleSE1@C4HelicopterHole";
ATTR__scrap := "C4HelicopterHoleSE1";
beginfig(4);
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2435.71,-96.17) -- (-2482.97,-94.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2482.97,-94.22) -- (-2482.97,-94.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2482.97,-94.22) -- (-2441.67,-93.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2482.97,-94.22) -- (-2435.71,-96.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2509.65,-93.96) -- (-2558.27,-94.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2509.65,-93.96) -- (-2482.97,-94.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2441.67,-93.41) -- (-2391.30,-94.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2441.67,-93.41) -- (-2482.97,-94.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2558.27,-94.13) -- (-2532.73,-96.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2558.27,-94.13) -- (-2509.65,-93.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2391.30,-94.84) -- (-2352.58,-94.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2391.30,-94.84) -- (-2441.67,-93.41)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2532.73,-96.26) -- (-2511.24,-96.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2532.73,-96.26) -- (-2558.27,-94.13)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2511.24,-96.28) -- (-2485.28,-98.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2511.24,-96.28) -- (-2532.73,-96.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2352.58,-94.20) -- (-2324.60,-95.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2352.58,-94.20) -- (-2391.30,-94.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2485.28,-98.24) -- (-2438.76,-99.81)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2485.28,-98.24) -- (-2511.24,-96.28)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2324.60,-95.03) -- (-2286.70,-95.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2324.60,-95.03) -- (-2352.58,-94.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2286.70,-95.15) -- (-2253.18,-98.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2286.70,-95.15) -- (-2324.60,-95.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2253.18,-98.34) -- (-2215.74,-97.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2253.18,-98.34) -- (-2286.70,-95.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2215.74,-97.98) -- (-2200.05,-99.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2215.74,-97.98) -- (-2253.18,-98.34)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2200.05,-99.06) -- (-2190.57,-94.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2200.05,-99.06) -- (-2215.74,-97.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2190.57,-94.58) -- (-2168.23,-97.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2190.57,-94.58) -- (-2200.05,-99.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2168.23,-97.00) -- (-2160.61,-97.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2168.23,-97.00) -- (-2190.57,-94.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2160.61,-97.09) -- (-2150.62,-95.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2160.61,-97.09) -- (-2168.23,-97.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2150.62,-95.15) -- (-2136.02,-97.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2150.62,-95.15) -- (-2160.61,-97.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2136.02,-97.47) -- (-2121.72,-97.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2136.02,-97.47) -- (-2150.62,-95.15)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2121.72,-97.02) -- (-2107.51,-98.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2121.72,-97.02) -- (-2136.02,-97.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2107.51,-98.62) -- (-2071.25,-98.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2107.51,-98.62) -- (-2121.72,-97.02)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2071.25,-98.77) -- (-2070.18,-97.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2071.25,-98.77) -- (-2107.51,-98.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2070.18,-97.43) -- (-2043.39,-96.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2070.18,-97.43) -- (-2071.25,-98.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2043.39,-96.22) -- (-2002.80,-97.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2043.39,-96.22) -- (-2070.18,-97.43)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2002.80,-97.53) -- (-1965.58,-95.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-2002.80,-97.53) -- (-2043.39,-96.22)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1965.58,-95.92) -- (-1925.11,-86.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1965.58,-95.92) -- (-2002.80,-97.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1925.11,-86.47) -- (-1912.43,-82.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1925.11,-86.47) -- (-1965.58,-95.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1912.43,-82.37) -- (-1872.88,-87.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1912.43,-82.37) -- (-1925.11,-86.47)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1872.88,-87.98) -- (-1845.92,-82.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1872.88,-87.98) -- (-1912.43,-82.37)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1845.92,-82.99) -- (-1798.60,-81.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1845.92,-82.99) -- (-1872.88,-87.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1798.60,-81.63) -- (-1738.12,-76.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1798.60,-81.63) -- (-1845.92,-82.99)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1738.12,-76.00) -- (-1688.26,-84.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1738.12,-76.00) -- (-1798.60,-81.63)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1688.26,-84.66) -- (-1626.05,-83.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1688.26,-84.66) -- (-1738.12,-76.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1626.05,-83.58) -- (-1562.74,-84.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1626.05,-83.58) -- (-1688.26,-84.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1562.74,-84.92) -- (-1504.47,-84.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1562.74,-84.92) -- (-1626.05,-83.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1504.47,-84.58) -- (-1457.35,-84.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1504.47,-84.58) -- (-1562.74,-84.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1457.35,-84.77) -- (-1401.27,-84.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1457.35,-84.77) -- (-1504.47,-84.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1401.27,-84.79) -- (-1353.12,-84.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1401.27,-84.79) -- (-1457.35,-84.77)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1353.12,-84.03) -- (-1329.78,-84.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1353.12,-84.03) -- (-1401.27,-84.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1329.78,-84.79) -- (-1319.34,-85.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1329.78,-84.79) -- (-1353.12,-84.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1319.34,-85.49) -- (-1273.84,-84.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1319.34,-85.49) -- (-1329.78,-84.79)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1273.84,-84.62) -- (-1248.95,-84.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1273.84,-84.62) -- (-1319.34,-85.49)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1248.95,-84.05) -- (-1192.99,-84.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1248.95,-84.05) -- (-1273.84,-84.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1192.99,-84.05) -- (-1179.15,-81.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1192.99,-84.05) -- (-1248.95,-84.05)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1179.15,-81.54) -- (-1154.80,-71.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1179.15,-81.54) -- (-1179.15,-81.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1154.80,-71.69) -- (-1179.15,-81.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1147.57,-81.96) -- (-1089.60,-82.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1147.57,-81.96) -- (-1179.15,-81.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1089.60,-82.54) -- (-1028.96,-79.35)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1089.60,-82.54) -- (-1147.57,-81.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1028.96,-79.35) -- (-985.67,-71.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-1028.96,-79.35) -- (-1089.60,-82.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-985.67,-71.62) -- (-926.44,-68.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-985.67,-71.62) -- (-1028.96,-79.35)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-926.44,-68.10) -- (-881.36,-78.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-926.44,-68.10) -- (-985.67,-71.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-881.36,-78.80) -- (-824.45,-79.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-881.36,-78.80) -- (-926.44,-68.10)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-824.45,-79.06) -- (-763.88,-78.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-824.45,-79.06) -- (-881.36,-78.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-763.88,-78.46) -- (-695.61,-77.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-763.88,-78.46) -- (-824.45,-79.06)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-695.61,-77.33) -- (-677.35,-76.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-695.61,-77.33) -- (-763.88,-78.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-677.35,-76.78) -- (-659.70,-77.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-677.35,-76.78) -- (-695.61,-77.33)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-659.70,-77.17) -- (-607.05,-78.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-659.70,-77.17) -- (-677.35,-76.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-607.05,-78.76) -- (-546.92,-78.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-607.05,-78.76) -- (-659.70,-77.17)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-546.92,-78.27) -- (-486.23,-72.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-546.92,-78.27) -- (-607.05,-78.76)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-486.23,-72.58) -- (-465.02,-72.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-486.23,-72.58) -- (-546.92,-78.27)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-465.02,-72.39) -- (-424.85,-72.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-465.02,-72.39) -- (-486.23,-72.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-424.85,-72.58) -- (-374.53,-74.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-424.85,-72.58) -- (-465.02,-72.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-374.53,-74.91) -- (-349.92,-75.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-374.53,-74.91) -- (-424.85,-72.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-349.92,-75.89) -- (-319.66,-73.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-349.92,-75.89) -- (-374.53,-74.91)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-319.66,-73.70) -- (-285.17,-68.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-319.66,-73.70) -- (-349.92,-75.89)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-285.17,-68.65) -- (-245.31,-70.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-285.17,-68.65) -- (-319.66,-73.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-245.31,-70.45) -- (-208.47,-65.85)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-245.31,-70.45) -- (-245.31,-70.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-208.47,-65.85) -- (-245.31,-70.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-192.62,-69.90) -- (-161.29,-68.08)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-192.62,-69.90) -- (-245.31,-70.45)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-161.29,-68.08) -- (-127.75,-66.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-161.29,-68.08) -- (-192.62,-69.90)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-127.75,-66.29) -- (-96.38,-66.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-127.75,-66.29) -- (-161.29,-68.08)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-96.38,-66.52) -- (-23.44,-66.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-96.38,-66.52) -- (-127.75,-66.29)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-23.44,-66.53) -- (17.61,-64.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((-23.44,-66.53) -- (-96.38,-66.52)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.61,-64.80) -- (89.25,-63.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((17.61,-64.80) -- (-23.44,-66.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((89.25,-63.66) -- (115.63,-60.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((89.25,-63.66) -- (17.61,-64.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((115.63,-60.56) -- (129.72,-59.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((115.63,-60.56) -- (89.25,-63.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((129.72,-59.98) -- (168.91,-59.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((129.72,-59.98) -- (115.63,-60.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((168.91,-59.20) -- (212.83,-55.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((168.91,-59.20) -- (129.72,-59.98)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((212.83,-55.56) -- (247.08,-57.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((212.83,-55.56) -- (168.91,-59.20)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((247.08,-57.86) -- (272.78,-55.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((247.08,-57.86) -- (212.83,-55.56)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((272.78,-55.80) -- (341.80,-56.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((272.78,-55.80) -- (247.08,-57.86)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((341.80,-56.25) -- (381.14,-49.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((341.80,-56.25) -- (272.78,-55.80)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((381.14,-49.19) -- (428.42,-47.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((381.14,-49.19) -- (341.80,-56.25)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((428.42,-47.92) -- (489.14,-45.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((428.42,-47.92) -- (381.14,-49.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((489.14,-45.69) -- (515.70,-46.64)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((489.14,-45.69) -- (428.42,-47.92)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((515.70,-46.64) -- (550.26,-45.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((515.70,-46.64) -- (489.14,-45.69)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((550.26,-45.96) -- (584.05,-41.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((550.26,-45.96) -- (515.70,-46.64)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((584.05,-41.65) -- (601.40,-40.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((584.05,-41.65) -- (550.26,-45.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((601.40,-40.00) -- (636.92,-37.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((601.40,-40.00) -- (584.05,-41.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((636.92,-37.55) -- (673.90,-35.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((636.92,-37.55) -- (601.40,-40.00)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((673.90,-35.58) -- (710.92,-35.67)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((673.90,-35.58) -- (636.92,-37.55)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((710.92,-35.67) -- (748.60,-36.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((710.92,-35.67) -- (673.90,-35.58)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((748.60,-36.03) -- (798.32,-30.93)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((748.60,-36.03) -- (710.92,-35.67)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((798.32,-30.93) -- (846.49,-31.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((798.32,-30.93) -- (748.60,-36.03)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((846.49,-31.46) -- (893.29,-31.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((846.49,-31.46) -- (798.32,-30.93)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((893.29,-31.74) -- (925.94,-28.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((893.29,-31.74) -- (846.49,-31.46)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((925.94,-28.61) -- (943.39,-27.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((925.94,-28.61) -- (893.29,-31.74)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((943.39,-27.62) -- (983.74,-31.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((943.39,-27.62) -- (925.94,-28.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((983.74,-31.14) -- (1009.97,-29.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((983.74,-31.14) -- (943.39,-27.62)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1009.97,-29.70) -- (1091.76,-30.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1009.97,-29.70) -- (983.74,-31.14)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1091.76,-30.53) -- (1138.65,-29.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1091.76,-30.53) -- (1009.97,-29.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1138.65,-29.61) -- (1163.68,-29.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1138.65,-29.61) -- (1091.76,-30.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1163.68,-29.70) -- (1171.81,-30.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1163.68,-29.70) -- (1138.65,-29.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1171.81,-30.23) -- (1190.58,-29.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1171.81,-30.23) -- (1163.68,-29.70)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1190.58,-29.21) -- (1216.12,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1190.58,-29.21) -- (1171.81,-30.23)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1216.12,-30.31) -- (1246.95,-30.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1216.12,-30.31) -- (1190.58,-29.21)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1246.95,-30.84) -- (1301.12,-30.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1246.95,-30.84) -- (1216.12,-30.31)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1301.12,-30.61) -- (1349.26,-29.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1301.12,-30.61) -- (1246.95,-30.84)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1349.26,-29.97) -- (1398.85,-22.67)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1349.26,-29.97) -- (1301.12,-30.61)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1398.85,-22.67) -- (1442.94,-19.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1398.85,-22.67) -- (1349.26,-29.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1442.94,-19.01) -- (1494.14,-22.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1442.94,-19.01) -- (1398.85,-22.67)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1494.14,-22.54) -- (1514.03,-19.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1494.14,-22.54) -- (1442.94,-19.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1514.03,-19.97) -- (1544.66,-21.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1514.03,-19.97) -- (1494.14,-22.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1544.66,-21.07) -- (1591.13,-19.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1544.66,-21.07) -- (1514.03,-19.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1591.13,-19.42) -- (1600.65,-19.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1591.13,-19.42) -- (1544.66,-21.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1600.65,-19.39) -- (1787.84,-21.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1600.65,-19.39) -- (1591.13,-19.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1787.84,-21.26) -- (1818.92,-16.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1787.84,-21.26) -- (1600.65,-19.39)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1818.92,-16.97) -- (1852.67,-13.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1818.92,-16.97) -- (1787.84,-21.26)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1852.67,-13.38) -- (1875.31,-10.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1852.67,-13.38) -- (1818.92,-16.97)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1875.31,-10.01) -- (1897.72,-11.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1875.31,-10.01) -- (1852.67,-13.38)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1897.72,-11.18) -- (1921.81,-13.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1897.72,-11.18) -- (1875.31,-10.01)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1921.81,-13.07) -- (1974.45,-13.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1921.81,-13.07) -- (1897.72,-11.18)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1974.45,-13.09) -- (2065.47,-8.78)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((1974.45,-13.09) -- (1921.81,-13.07)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2065.47,-8.78) -- (2135.75,-9.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2065.47,-8.78) -- (1974.45,-13.09)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2167.74,8.36) -- (2135.75,-9.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2192.02,-10.11) -- (2234.73,-10.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2192.02,-10.11) -- (2135.75,-9.96)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2234.73,-10.24) -- (2329.79,-8.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2234.73,-10.24) -- (2192.02,-10.11)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2329.79,-8.42) -- (2377.15,-9.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2329.79,-8.42) -- (2234.73,-10.24)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2377.15,-9.65) -- (2429.94,-8.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2377.15,-9.65) -- (2329.79,-8.42)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2429.94,-8.54) -- (2459.20,-6.12)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2429.94,-8.54) -- (2377.15,-9.65)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2459.20,-6.12) -- (2465.69,-6.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2459.20,-6.12) -- (2429.94,-8.54)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2465.69,-6.19) -- (2476.12,-4.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2465.69,-6.19) -- (2459.20,-6.12)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2476.12,-4.66) -- (2521.68,-2.53)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2476.12,-4.66) -- (2465.69,-6.19)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2521.68,-2.53) -- (2476.12,-4.66)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2135.75,-9.96) -- (2167.74,8.36)));
ATTR__shotflag_splay := false;
ATTR__shotflag_duplicate := false;
ATTR__shotflag_approx := false;
drawoptions();
l_survey_cave(((2135.75,-9.96) -- (2135.75,-9.96)));
endfig;
beginfig(5);
draw_upscrap(1)(1,((-1163.26,-84.33)
 .. controls (-1163.26,-84.33) and (-1157.79,-85.29) .. (-1154.62,-85.10)
 .. controls (-1151.45,-84.91) and (-1151.26,-84.14) .. (-1146.17,-84.43)
 .. controls (-1141.09,-84.72) and (-1135.71,-84.33) .. (-1131.10,-84.24)
 .. controls (-1126.49,-84.14) and (-1127.55,-83.47) .. (-1122.27,-83.76)
 .. controls (-1116.99,-84.04) and (-1117.57,-84.81) .. (-1111.33,-84.43)
 .. controls (-1105.09,-84.04) and (-1103.93,-83.85) .. (-1098.85,-84.33)
 .. controls (-1093.76,-84.81) and (-1092.22,-83.95) .. (-1088.48,-83.66)
 .. controls (-1084.73,-83.37) and (-1087.90,-83.18) .. (-1082.53,-83.28)
 .. controls (-1077.15,-83.37) and (-1072.06,-83.85) .. (-1067.55,-83.66)
 .. controls (-1063.04,-83.47) and (-1069.47,-82.89) .. (-1060.83,-83.38)
 .. controls (-1052.19,-83.86) and (-1052.96,-84.53) .. (-1046.33,-84.24)
 .. controls (-1039.71,-83.95) and (-1034.14,-83.67) .. (-1031.93,-83.48)
 .. controls (-1029.73,-83.28) and (-1030.40,-82.80) .. (-1027.23,-83.19)
 .. controls (-1024.06,-83.57) and (-1021.57,-81.36) .. (-1018.78,-81.08)
 .. controls (-1016.00,-80.79) and (-1015.90,-80.40) .. (-1011.20,-80.12)
 .. controls (-1006.49,-79.83) and (-1009.28,-80.31) .. (-1004.57,-79.92)
 .. controls (-999.87,-79.54) and (-996.80,-78.77) .. (-992.76,-78.00)
 .. controls (-988.73,-77.24) and (-992.38,-77.81) .. (-988.16,-77.24)
 .. controls (-983.93,-76.66) and (-988.83,-77.24) .. (-981.63,-76.56)
 .. controls (-974.43,-75.89) and (-977.98,-76.18) .. (-972.80,-75.70)
 .. controls (-967.61,-75.22) and (-967.13,-74.64) .. (-963.48,-74.55)
 .. controls (-959.84,-74.45) and (-958.11,-75.22) .. (-953.31,-74.45)
 .. controls (-948.51,-73.68) and (-947.93,-73.49) .. (-943.04,-73.39)
 .. controls (-938.14,-73.30) and (-938.81,-73.68) .. (-935.07,-73.30)
 .. controls (-931.32,-72.91) and (-934.11,-73.39) .. (-929.69,-72.72)
 .. controls (-925.28,-72.05) and (-926.62,-72.15) .. (-921.05,-72.24)
 .. controls (-915.48,-72.34) and (-918.17,-72.15) .. (-913.95,-72.34)
 .. controls (-909.72,-72.53) and (-908.57,-72.63) .. (-905.31,-73.39)
 .. controls (-902.04,-74.16) and (-901.56,-74.45) .. (-897.24,-75.51)
 .. controls (-892.92,-76.56) and (-891.96,-76.95) .. (-888.51,-77.91)
 .. controls (-885.05,-78.87) and (-888.09,-78.13) .. (-884.28,-79.06)
 .. controls (-875.64,-81.17) and (-879.96,-82.99) .. (-873.53,-82.71)
 .. controls (-867.10,-82.42) and (-868.93,-82.52) .. (-864.61,-82.23)
 .. controls (-860.29,-81.94) and (-858.85,-82.90) .. (-853.18,-82.23)
 .. controls (-847.52,-81.56) and (-850.30,-81.08) .. (-842.14,-81.56)
 .. controls (-833.98,-82.04) and (-833.98,-82.14) .. (-830.43,-81.95)
 .. controls (-826.88,-81.75) and (-829.76,-81.75) .. (-824.29,-81.56)
 .. controls (-818.81,-81.37) and (-818.24,-81.27) .. (-815.74,-80.89)
 .. controls (-813.24,-80.51) and (-803.07,-81.27) .. (-802.30,-81.18)
 .. controls (-801.53,-81.08) and (-800.67,-81.56) .. (-794.14,-81.27)
 .. controls (-787.61,-80.98) and (-791.64,-81.37) .. (-787.04,-80.89)
 .. controls (-782.43,-80.41) and (-787.13,-80.60) .. (-780.70,-80.21)
 .. controls (-774.27,-79.83) and (-776.00,-79.75) .. (-772.35,-80.02)
 .. controls (-763.32,-80.69) and (-763.23,-80.88) .. (-760.16,-81.08)
 .. controls (-757.09,-81.27) and (-757.37,-81.17) .. (-753.73,-80.98)
 .. controls (-750.08,-80.79) and (-745.08,-79.93) .. (-742.01,-79.26)
 .. controls (-738.94,-78.59) and (-740.19,-79.74) .. (-732.80,-79.07)
 .. controls (-725.40,-78.40) and (-723.29,-78.49) .. (-718.88,-78.69)
 .. controls (-714.46,-78.88) and (-716.00,-79.26) .. (-711.20,-79.36)
 .. controls (-706.40,-79.46) and (-710.04,-79.36) .. (-703.80,-79.84)
 .. controls (-697.56,-80.32) and (-699.39,-80.80) .. (-694.78,-80.61)
 .. controls (-690.17,-80.42) and (-690.94,-80.90) .. (-686.52,-79.84)
 .. controls (-682.11,-78.78) and (-681.72,-78.30) .. (-677.60,-78.49)
 .. controls (-673.47,-78.68) and (-676.54,-78.68) .. (-669.63,-78.88)
 .. controls (-662.72,-79.08) and (-660.99,-79.27) .. (-658.88,-79.08)
 .. controls (-656.76,-78.88) and (-651.48,-79.36) .. (-645.72,-78.88)
 .. controls (-639.96,-78.40) and (-640.35,-77.63) .. (-636.60,-78.30)
 .. controls (-632.86,-78.97) and (-635.64,-79.07) .. (-629.11,-79.07)
 .. controls (-622.59,-79.07) and (-624.79,-79.16) .. (-620.95,-79.07)
 .. controls (-617.11,-78.97) and (-616.92,-79.16) .. (-613.56,-78.97)
 .. controls (-610.20,-78.77) and (-609.34,-79.83) .. (-606.46,-79.64)
 .. controls (-603.58,-79.45) and (-606.36,-79.45) .. (-600.41,-78.68)
 .. controls (-594.46,-77.91) and (-598.30,-77.72) .. (-590.81,-78.20)
 .. controls (-583.32,-78.68) and (-581.98,-79.07) .. (-577.85,-79.16)
 .. controls (-573.72,-79.26) and (-575.74,-79.64) .. (-572.57,-79.16)
 .. controls (-569.40,-78.69) and (-570.56,-80.32) .. (-565.66,-79.65)
 .. controls (-560.76,-78.98) and (-559.90,-77.92) .. (-555.10,-78.50)
 .. controls (-550.30,-79.07) and (-552.99,-79.27) .. (-547.80,-79.07)
 .. controls (-542.62,-78.88) and (-541.18,-78.79) .. (-538.59,-78.21)
 .. controls (-536.00,-77.63) and (-538.49,-77.44) .. (-532.83,-77.63)
 .. controls (-527.16,-77.83) and (-529.95,-78.21) .. (-524.76,-77.83)
 .. controls (-519.58,-77.44) and (-521.21,-77.06) .. (-516.99,-77.25)
 .. controls (-512.76,-77.44) and (-507.10,-78.59) .. (-504.89,-78.11)
 .. controls (-502.68,-77.63) and (-497.69,-78.31) .. (-493.08,-78.50)
 .. controls (-488.47,-78.69) and (-486.55,-79.17) .. (-483.67,-79.17)
 .. controls (-480.79,-79.17) and (-482.71,-78.88) .. (-475.51,-78.78)
 .. controls (-468.31,-78.69) and (-465.63,-79.17) .. (-462.84,-78.88)
 .. controls (-460.06,-78.59) and (-464.57,-78.78) .. (-458.33,-78.59)
 .. controls (-452.09,-78.40) and (-454.01,-78.69) .. (-449.12,-78.30)
 .. controls (-444.22,-77.92) and (-447.10,-79.27) .. (-442.01,-78.31)
 .. controls (-436.92,-77.35) and (-437.60,-77.16) .. (-434.24,-76.77)
),
1,((-434.24,-76.77)
 .. controls (-434.24,-76.77) and (-435.29,-76.68) .. (-431.93,-76.10)
 .. controls (-428.57,-75.53) and (-424.25,-75.33) .. (-420.51,-74.76)
 .. controls (-416.76,-74.18) and (-410.91,-74.56) .. (-407.16,-74.66)
 .. controls (-403.42,-74.75) and (-403.99,-74.75) .. (-400.15,-74.56)
 .. controls (-396.31,-74.37) and (-397.95,-73.89) .. (-392.67,-74.65)
 .. controls (-387.39,-75.42) and (-391.03,-75.90) .. (-382.97,-75.99)
 .. controls (-374.91,-76.09) and (-374.71,-76.28) .. (-372.03,-76.47)
 .. controls (-369.34,-76.66) and (-369.82,-76.76) .. (-363.87,-77.05)
 .. controls (-357.92,-77.34) and (-362.04,-77.05) .. (-354.27,-77.34)
 .. controls (-346.49,-77.63) and (-348.32,-77.63) .. (-343.52,-77.34)
 .. controls (-338.72,-77.06) and (-341.12,-77.73) .. (-336.32,-76.86)
 .. controls (-331.52,-76.00) and (-331.32,-76.39) .. (-327.29,-75.81)
 .. controls (-323.26,-75.24) and (-323.55,-75.72) .. (-320.57,-75.24)
 .. controls (-317.60,-74.76) and (-320.28,-75.14) .. (-314.62,-74.37)
 .. controls (-308.96,-73.60) and (-309.63,-74.08) .. (-304.83,-73.22)
 .. controls (-300.03,-72.35) and (-304.35,-71.68) .. (-297.82,-72.06)
 .. controls (-291.29,-72.45) and (-283.23,-73.12) .. (-281.88,-73.40)
 .. controls (-280.54,-73.69) and (-282.65,-75.71) .. (-277.18,-74.94)
 .. controls (-271.71,-74.17) and (-275.64,-74.65) .. (-268.15,-73.98)
 .. controls (-260.67,-73.31) and (-263.55,-73.41) .. (-258.46,-72.93)
 .. controls (-253.37,-72.45) and (-254.23,-72.84) .. (-249.53,-72.26)
 .. controls (-244.83,-71.69) and (-245.50,-71.69) .. (-240.70,-71.49)
 .. controls (-235.90,-71.30) and (-236.47,-70.82) .. (-232.15,-71.01)
 .. controls (-227.83,-71.21) and (-229.47,-71.40) .. (-223.71,-71.59)
 .. controls (-217.95,-71.78) and (-218.91,-72.17) .. (-215.64,-71.97)
 .. controls (-212.38,-71.78) and (-210.27,-71.30) .. (-208.54,-71.78)
 .. controls (-206.81,-72.26) and (-203.16,-71.40) .. (-202.11,-71.40)
 .. controls (-201.05,-71.40) and (-198.75,-70.72) .. (-195.96,-70.82)
 .. controls (-193.18,-70.92) and (-194.62,-71.40) .. (-190.97,-71.20)
 .. controls (-187.32,-71.01) and (-189.05,-71.68) .. (-184.35,-70.92)
 .. controls (-179.64,-70.15) and (-180.22,-69.96) .. (-176.67,-69.96)
 .. controls (-173.11,-69.96) and (-176.76,-70.24) .. (-171.39,-69.96)
 .. controls (-166.01,-69.67) and (-165.82,-69.96) .. (-162.46,-69.38)
 .. controls (-159.10,-68.80) and (-160.35,-68.80) .. (-156.89,-68.90)
 .. controls (-153.43,-68.99) and (-155.26,-68.71) .. (-148.92,-68.99)
 .. controls (-142.59,-69.28) and (-141.05,-69.09) .. (-137.79,-69.18)
 .. controls (-134.52,-69.28) and (-135.00,-68.99) .. (-131.35,-69.37)
 .. controls (-127.71,-69.76) and (-127.42,-69.08) .. (-122.43,-68.70)
 .. controls (-117.44,-68.32) and (-120.22,-68.32) .. (-114.36,-68.13)
 .. controls (-108.51,-67.94) and (-111.68,-68.61) .. (-106.11,-67.94)
 .. controls (-100.54,-67.27) and (-101.50,-66.88) .. (-98.14,-67.07)
 .. controls (-94.78,-67.27) and (-98.04,-67.17) .. (-92.28,-67.46)
 .. controls (-86.52,-67.75) and (-88.64,-67.07) .. (-83.36,-67.65)
 .. controls (-78.08,-68.22) and (-81.44,-67.46) .. (-76.54,-67.94)
 .. controls (-71.64,-68.42) and (-73.18,-68.32) .. (-68.48,-68.42)
 .. controls (-63.77,-68.51) and (-66.27,-67.65) .. (-61.85,-68.51)
 .. controls (-57.44,-69.37) and (-55.04,-68.03) .. (-53.31,-68.03)
 .. controls (-51.58,-68.03) and (-50.14,-67.36) .. (-46.01,-67.65)
 .. controls (-41.88,-67.93) and (-44.96,-68.13) .. (-40.06,-68.32)
 .. controls (-35.16,-68.51) and (-35.93,-68.32) .. (-31.80,-68.03)
 .. controls (-27.68,-67.74) and (-31.32,-67.64) .. (-26.24,-67.93)
 .. controls (-21.15,-68.22) and (-21.82,-68.22) .. (-19.42,-68.32)
),
1,((-19.42,-68.32)
 -- (-19.42,-68.32)),
1,((-19.42,-68.32)
 .. controls (-19.42,-68.32) and (-15.87,-68.70) .. (-14.43,-68.60)
 .. controls (-12.99,-68.51) and (-11.16,-68.22) .. (-6.94,-67.93)
 .. controls (-2.72,-67.64) and (-5.21,-67.26) .. (0.93,-67.64)
 .. controls (7.08,-68.03) and (7.36,-67.74) .. (11.30,-67.93)
 .. controls (15.24,-68.12) and (14.47,-67.36) .. (18.50,-67.64)
 .. controls (22.53,-67.93) and (20.13,-68.32) .. (25.70,-68.12)
 .. controls (31.27,-67.93) and (35.30,-68.13) .. (38.56,-67.84)
 .. controls (41.83,-67.55) and (41.44,-68.22) .. (46.72,-68.13)
 .. controls (52.00,-68.03) and (52.77,-67.94) .. (56.52,-67.55)
 .. controls (60.26,-67.17) and (59.59,-66.98) .. (63.52,-66.98)
 .. controls (67.46,-66.98) and (65.54,-67.65) .. (70.53,-67.55)
 .. controls (75.52,-67.46) and (76.68,-67.55) .. (78.98,-67.46)
 .. controls (81.28,-67.36) and (79.56,-67.55) .. (84.36,-66.88)
 .. controls (89.16,-66.21) and (85.51,-66.31) .. (91.56,-66.21)
 .. controls (97.60,-66.11) and (96.16,-67.27) .. (100.29,-66.59)
 .. controls (104.42,-65.92) and (103.17,-65.83) .. (109.99,-65.35)
 .. controls (116.81,-64.87) and (113.16,-64.39) .. (119.21,-64.48)
 .. controls (125.25,-64.57) and (123.72,-64.57) .. (128.52,-64.66)
 .. controls (133.32,-64.75) and (132.16,-65.14) .. (136.58,-64.66)
 .. controls (140.99,-64.18) and (144.74,-64.28) .. (147.71,-63.90)
 .. controls (150.69,-63.51) and (150.40,-63.80) .. (153.95,-63.32)
 .. controls (157.51,-62.84) and (157.60,-62.46) .. (161.25,-62.27)
 .. controls (164.90,-62.08) and (171.14,-61.12) .. (172.58,-61.02)
 .. controls (174.02,-60.93) and (173.63,-62.46) .. (178.24,-61.98)
 .. controls (182.85,-61.50) and (179.97,-61.12) .. (187.75,-60.93)
 .. controls (195.52,-60.74) and (194.27,-60.83) .. (198.59,-60.45)
 .. controls (202.91,-60.06) and (202.82,-60.83) .. (207.91,-61.02)
 .. controls (213.00,-61.22) and (209.25,-60.45) .. (215.01,-61.12)
 .. controls (220.77,-61.79) and (222.21,-61.98) .. (224.80,-61.88)
 .. controls (227.40,-61.79) and (225.67,-61.31) .. (231.14,-61.69)
 .. controls (236.61,-62.07) and (237.28,-62.26) .. (241.99,-62.17)
 .. controls (246.69,-62.07) and (249.38,-61.97) .. (256.10,-61.11)
 .. controls (262.82,-60.25) and (265.12,-59.19) .. (269.44,-58.52)
 .. controls (273.76,-57.85) and (272.23,-58.04) .. (276.93,-57.66)
 .. controls (281.63,-57.27) and (279.43,-56.99) .. (284.80,-57.37)
 .. controls (290.18,-57.75) and (290.75,-58.14) .. (295.84,-58.14)
 .. controls (300.93,-58.14) and (300.45,-58.04) .. (304.67,-57.94)
 .. controls (308.90,-57.85) and (311.39,-57.46) .. (315.52,-57.75)
 .. controls (319.65,-58.04) and (320.03,-58.71) .. (325.70,-58.61)
 .. controls (331.36,-58.52) and (334.82,-58.42) .. (338.27,-58.52)
 .. controls (341.73,-58.61) and (340.19,-58.90) .. (344.51,-58.23)
 .. controls (348.83,-57.56) and (346.82,-57.65) .. (351.14,-57.36)
 .. controls (355.46,-57.08) and (354.79,-57.17) .. (361.12,-56.12)
 .. controls (367.46,-55.06) and (367.46,-55.64) .. (372.45,-54.39)
 .. controls (377.44,-53.14) and (377.73,-53.24) .. (382.24,-52.66)
 .. controls (386.75,-52.08) and (384.45,-52.47) .. (389.35,-51.60)
 .. controls (394.24,-50.74) and (391.55,-50.36) .. (396.74,-50.55)
 .. controls (401.92,-50.74) and (400.96,-51.41) .. (406.24,-51.12)
 .. controls (411.52,-50.84) and (416.42,-51.03) .. (419.68,-50.93)
 .. controls (422.95,-50.84) and (418.34,-51.03) .. (426.11,-50.93)
 .. controls (433.89,-50.84) and (430.15,-50.84) .. (435.81,-50.84)
 .. controls (441.48,-50.84) and (441.48,-50.84) .. (446.47,-50.64)
 .. controls (451.46,-50.45) and (451.46,-50.35) .. (455.39,-50.06)
 .. controls (459.33,-49.78) and (457.99,-50.26) .. (462.11,-49.68)
 .. controls (466.24,-49.10) and (464.61,-49.10) .. (469.51,-48.53)
 .. controls (474.40,-47.95) and (474.31,-49.58) .. (480.16,-48.62)
 .. controls (486.02,-47.66) and (484.19,-46.89) .. (488.23,-47.37)
 .. controls (492.26,-47.85) and (489.38,-48.23) .. (495.52,-48.05)
 .. controls (501.67,-47.86) and (497.82,-48.05) .. (503.97,-47.76)
 .. controls (510.11,-47.48) and (509.35,-47.58) .. (514.05,-47.77)
 .. controls (518.75,-47.96) and (516.26,-48.25) .. (521.06,-48.06)
 .. controls (525.86,-47.87) and (521.83,-47.39) .. (527.11,-47.77)
 .. controls (532.39,-48.15) and (532.39,-48.06) .. (535.27,-48.15)
 .. controls (538.15,-48.25) and (534.79,-48.92) .. (539.87,-47.96)
 .. controls (544.96,-47.00) and (544.48,-46.81) .. (546.98,-46.90)
 .. controls (549.47,-47.00) and (550.72,-47.57) .. (556.77,-47.19)
 .. controls (562.82,-46.81) and (560.80,-46.81) .. (565.31,-46.90)
 .. controls (569.83,-47.00) and (563.39,-47.48) .. (571.36,-46.90)
 .. controls (579.33,-46.33) and (575.97,-46.23) .. (581.63,-46.04)
 .. controls (587.30,-45.85) and (585.76,-45.85) .. (591.14,-45.65)
 .. controls (596.51,-45.46) and (593.25,-45.46) .. (598.34,-45.46)
 .. controls (603.43,-45.46) and (599.49,-45.75) .. (605.35,-45.37)
 .. controls (611.20,-44.98) and (608.13,-45.08) .. (613.31,-44.79)
 .. controls (618.50,-44.50) and (619.84,-45.36) .. (623.11,-44.40)
 .. controls (626.37,-43.44) and (623.39,-43.54) .. (629.06,-42.38)
 .. controls (634.72,-41.23) and (631.84,-41.52) .. (637.12,-40.85)
 .. controls (642.40,-40.17) and (638.85,-40.56) .. (644.03,-39.89)
 .. controls (649.22,-39.22) and (647.30,-39.60) .. (652.19,-39.03)
 .. controls (657.09,-38.45) and (655.46,-37.87) .. (660.07,-38.26)
 .. controls (664.67,-38.64) and (661.79,-38.16) .. (667.17,-38.84)
 .. controls (672.55,-39.51) and (671.68,-39.22) .. (675.71,-39.60)
 .. controls (679.75,-39.99) and (679.36,-40.28) .. (682.92,-40.18)
 .. controls (686.47,-40.08) and (697.80,-40.37) .. (699.43,-40.37)
),
1,((699.43,-40.37)
 -- (699.43,-40.37)),
1,((699.43,-40.37)
 .. controls (699.43,-40.37) and (699.71,-39.98) .. (703.36,-39.40)
 .. controls (707.01,-38.83) and (705.28,-38.73) .. (709.79,-38.73)
 .. controls (714.30,-38.73) and (713.25,-39.02) .. (717.28,-38.73)
 .. controls (721.31,-38.45) and (721.79,-37.97) .. (725.54,-37.97)
 .. controls (729.28,-37.97) and (727.65,-38.45) .. (732.06,-37.97)
 .. controls (736.48,-37.49) and (736.10,-37.88) .. (740.32,-38.17)
 .. controls (744.54,-38.46) and (743.87,-38.36) .. (746.94,-38.55)
 .. controls (750.02,-38.75) and (750.02,-39.04) .. (754.14,-39.13)
 .. controls (758.27,-39.23) and (755.10,-39.13) .. (762.21,-39.42)
 .. controls (769.31,-39.71) and (769.98,-39.42) .. (775.55,-38.94)
 .. controls (781.12,-38.46) and (782.18,-38.55) .. (789.86,-37.59)
 .. controls (797.54,-36.63) and (796.86,-37.59) .. (800.32,-36.06)
 .. controls (803.78,-34.52) and (800.80,-34.43) .. (807.14,-33.37)
 .. controls (813.47,-32.31) and (810.98,-32.31) .. (814.53,-32.02)
 .. controls (818.08,-31.74) and (815.20,-31.16) .. (820.48,-31.64)
 .. controls (825.76,-32.12) and (824.42,-32.41) .. (830.08,-32.69)
 .. controls (835.75,-32.98) and (834.21,-32.69) .. (839.20,-33.36)
 .. controls (844.19,-34.04) and (850.24,-34.71) .. (852.54,-34.42)
 .. controls (854.85,-34.13) and (855.90,-33.27) .. (860.61,-33.75)
 .. controls (865.31,-34.23) and (865.02,-33.94) .. (870.40,-33.85)
 .. controls (875.78,-33.75) and (872.70,-34.33) .. (879.04,-34.04)
 .. controls (885.38,-33.76) and (882.11,-34.33) .. (887.78,-33.76)
 .. controls (893.44,-33.18) and (890.85,-33.09) .. (895.84,-33.28)
 .. controls (900.83,-33.47) and (897.86,-33.95) .. (904.00,-33.57)
 .. controls (910.14,-33.18) and (917.15,-32.89) .. (919.94,-32.60)
 .. controls (922.72,-32.32) and (923.39,-32.70) .. (926.85,-32.80)
 .. controls (930.31,-32.89) and (929.06,-32.70) .. (932.80,-32.50)
 .. controls (936.55,-32.31) and (936.93,-32.12) .. (939.04,-32.02)
 .. controls (941.15,-31.92) and (941.15,-31.25) .. (945.57,-31.73)
 .. controls (949.98,-32.21) and (953.92,-33.65) .. (956.80,-33.46)
 .. controls (959.68,-33.27) and (959.10,-33.17) .. (963.14,-33.37)
 .. controls (967.17,-33.56) and (965.63,-33.75) .. (970.14,-33.75)
 .. controls (974.66,-33.75) and (971.78,-33.47) .. (976.67,-33.66)
 .. controls (981.57,-33.85) and (979.84,-34.62) .. (985.70,-33.66)
 .. controls (991.55,-32.70) and (991.84,-33.18) .. (995.78,-32.98)
 .. controls (999.71,-32.79) and (1000.10,-32.79) .. (1004.23,-33.08)
 .. controls (1008.35,-33.36) and (1007.30,-32.79) .. (1012.00,-33.17)
 .. controls (1016.70,-33.55) and (1018.82,-33.46) .. (1022.46,-33.46)
 .. controls (1026.11,-33.46) and (1024.86,-33.84) .. (1030.24,-33.46)
 .. controls (1035.62,-33.07) and (1034.56,-32.59) .. (1040.32,-32.88)
 .. controls (1046.08,-33.17) and (1046.08,-34.03) .. (1051.36,-33.46)
 .. controls (1056.64,-32.88) and (1057.12,-32.40) .. (1060.67,-32.50)
 .. controls (1064.22,-32.59) and (1061.92,-32.98) .. (1067.10,-32.59)
 .. controls (1072.29,-32.21) and (1073.06,-32.21) .. (1077.76,-32.31)
 .. controls (1082.46,-32.40) and (1081.02,-32.40) .. (1084.67,-32.40)
 .. controls (1088.32,-32.40) and (1091.01,-33.17) .. (1094.66,-32.69)
 .. controls (1098.30,-32.21) and (1102.91,-30.48) .. (1110.30,-30.96)
 .. controls (1117.70,-31.44) and (1117.60,-32.21) .. (1122.21,-32.31)
 .. controls (1126.82,-32.40) and (1123.17,-31.73) .. (1128.16,-32.31)
 .. controls (1133.15,-32.88) and (1129.98,-33.65) .. (1135.07,-33.27)
 .. controls (1140.16,-32.88) and (1138.82,-32.12) .. (1143.23,-32.79)
 .. controls (1147.65,-33.46) and (1146.59,-34.04) .. (1150.81,-33.46)
 .. controls (1155.04,-32.89) and (1154.75,-32.79) .. (1158.97,-32.89)
 .. controls (1163.20,-32.99) and (1161.09,-32.79) .. (1166.27,-32.99)
 .. controls (1171.46,-33.18) and (1176.35,-33.17) .. (1178.37,-32.98)
 .. controls (1180.39,-32.79) and (1186.53,-34.60) .. (1191.81,-34.22)
 .. controls (1197.09,-33.83) and (1193.34,-34.03) .. (1199.87,-34.22)
 .. controls (1206.40,-34.41) and (1204.96,-34.61) .. (1208.61,-34.41)
 .. controls (1212.25,-34.22) and (1210.05,-34.70) .. (1215.33,-34.13)
 .. controls (1220.61,-33.55) and (1220.51,-33.74) .. (1224.35,-33.94)
 .. controls (1228.19,-34.13) and (1228.19,-34.90) .. (1232.13,-34.13)
 .. controls (1236.06,-33.36) and (1234.81,-33.75) .. (1237.79,-33.27)
 .. controls (1240.77,-32.79) and (1239.33,-33.27) .. (1244.41,-32.50)
 .. controls (1249.50,-31.73) and (1246.53,-32.11) .. (1252.29,-31.35)
 .. controls (1258.05,-30.58) and (1261.98,-30.77) .. (1263.42,-31.06)
 .. controls (1264.86,-31.35) and (1269.76,-31.74) .. (1272.93,-31.93)
 .. controls (1276.09,-32.12) and (1274.65,-31.64) .. (1281.85,-32.41)
 .. controls (1289.05,-33.18) and (1286.17,-33.28) .. (1292.13,-33.18)
 .. controls (1298.08,-33.09) and (1295.58,-32.51) .. (1299.52,-33.09)
 .. controls (1303.46,-33.66) and (1301.44,-33.86) .. (1306.05,-34.05)
 .. controls (1310.66,-34.24) and (1310.46,-34.53) .. (1314.78,-34.14)
 .. controls (1319.10,-33.75) and (1319.49,-33.95) .. (1322.75,-33.56)
 .. controls (1326.02,-33.18) and (1324.38,-33.18) .. (1329.76,-32.89)
 .. controls (1335.14,-32.60) and (1335.90,-32.41) .. (1338.69,-32.12)
),
1,((1338.69,-32.12)
 .. controls (1338.69,-32.12) and (1341.95,-31.44) .. (1344.54,-31.44)
 .. controls (1347.13,-31.44) and (1348.38,-32.02) .. (1352.80,-31.83)
 .. controls (1357.21,-31.64) and (1356.25,-31.44) .. (1362.30,-31.06)
 .. controls (1368.35,-30.68) and (1364.13,-31.06) .. (1370.27,-30.48)
 .. controls (1376.41,-29.91) and (1376.61,-29.53) .. (1380.54,-29.53)
 .. controls (1384.48,-29.53) and (1380.73,-29.72) .. (1387.17,-29.53)
 .. controls (1393.60,-29.33) and (1390.24,-28.66) .. (1396.19,-28.47)
 .. controls (1402.14,-28.28) and (1410.88,-29.43) .. (1415.01,-27.61)
 .. controls (1419.13,-25.79) and (1416.83,-26.27) .. (1421.73,-25.11)
 .. controls (1426.62,-23.96) and (1422.88,-24.83) .. (1427.97,-23.68)
 .. controls (1433.05,-22.52) and (1431.52,-22.62) .. (1436.51,-21.95)
 .. controls (1441.50,-21.28) and (1438.81,-21.09) .. (1444.09,-21.09)
 .. controls (1449.37,-21.09) and (1450.62,-20.99) .. (1456.09,-20.80)
 .. controls (1461.57,-20.61) and (1460.22,-20.32) .. (1466.75,-21.09)
 .. controls (1473.28,-21.85) and (1478.56,-21.37) .. (1481.06,-21.47)
 .. controls (1483.55,-21.57) and (1488.06,-23.87) .. (1492.19,-24.06)
 .. controls (1496.32,-24.25) and (1492.86,-24.26) .. (1497.95,-24.35)
 .. controls (1503.04,-24.44) and (1507.46,-24.15) .. (1513.70,-23.67)
 .. controls (1519.94,-23.19) and (1515.42,-23.58) .. (1523.10,-23.19)
 .. controls (1530.78,-22.81) and (1529.82,-22.90) .. (1533.66,-22.62)
 .. controls (1537.50,-22.33) and (1533.57,-22.52) .. (1538.66,-22.23)
 .. controls (1543.74,-21.94) and (1541.15,-21.65) .. (1546.24,-22.23)
 .. controls (1551.33,-22.81) and (1554.69,-23.77) .. (1559.68,-23.96)
 .. controls (1564.67,-24.16) and (1561.50,-24.16) .. (1566.88,-24.54)
 .. controls (1572.26,-24.93) and (1572.93,-25.02) .. (1576.77,-24.83)
 .. controls (1580.61,-24.64) and (1579.36,-24.35) .. (1584.06,-24.35)
 .. controls (1588.77,-24.36) and (1586.46,-24.16) .. (1592.42,-24.26)
 .. controls (1598.37,-24.35) and (1594.72,-24.93) .. (1600.58,-24.16)
 .. controls (1606.43,-23.39) and (1604.51,-25.22) .. (1609.89,-24.35)
 .. controls (1615.26,-23.49) and (1610.56,-22.82) .. (1617.66,-23.39)
 .. controls (1624.77,-23.97) and (1625.73,-24.93) .. (1632.16,-24.54)
 .. controls (1638.59,-24.16) and (1638.59,-24.35) .. (1645.22,-23.78)
 .. controls (1651.84,-23.20) and (1652.90,-23.20) .. (1658.66,-23.39)
 .. controls (1664.42,-23.58) and (1670.75,-24.06) .. (1673.82,-23.97)
 .. controls (1676.90,-23.87) and (1692.64,-23.10) .. (1692.64,-23.10)
 .. controls (1692.64,-23.10) and (1694.18,-23.49) .. (1699.94,-23.58)
 .. controls (1705.70,-23.68) and (1707.04,-23.58) .. (1711.17,-23.49)
 .. controls (1715.30,-23.39) and (1717.12,-23.49) .. (1720.00,-23.58)
 .. controls (1722.88,-23.68) and (1721.25,-23.49) .. (1726.34,-23.77)
 .. controls (1731.42,-24.06) and (1736.03,-25.02) .. (1740.06,-24.25)
 .. controls (1744.10,-23.49) and (1741.31,-23.29) .. (1749.18,-23.39)
 .. controls (1757.06,-23.49) and (1758.21,-23.68) .. (1760.13,-23.68)
 .. controls (1762.05,-23.68) and (1759.17,-23.58) .. (1767.52,-23.39)
 .. controls (1775.87,-23.20) and (1774.91,-23.10) .. (1779.14,-23.10)
 .. controls (1783.36,-23.10) and (1781.82,-23.10) .. (1785.57,-23.01)
 .. controls (1789.31,-22.91) and (1787.97,-23.68) .. (1793.54,-22.81)
 .. controls (1799.11,-21.95) and (1800.07,-22.71) .. (1803.81,-21.75)
 .. controls (1807.55,-20.79) and (1806.11,-20.31) .. (1810.53,-20.50)
 .. controls (1814.95,-20.69) and (1819.46,-20.40) .. (1821.38,-19.64)
),
1,((1821.38,-19.64)
 .. controls (1821.38,-19.64) and (1824.06,-19.06) .. (1827.33,-19.16)
 .. controls (1830.59,-19.25) and (1831.84,-20.12) .. (1835.39,-19.54)
 .. controls (1838.94,-18.96) and (1839.71,-19.54) .. (1843.26,-18.39)
 .. controls (1846.82,-17.24) and (1846.14,-17.52) .. (1849.41,-16.76)
 .. controls (1852.67,-15.99) and (1853.63,-16.56) .. (1856.51,-15.89)
 .. controls (1859.39,-15.22) and (1859.58,-14.55) .. (1863.23,-14.36)
 .. controls (1866.88,-14.17) and (1862.75,-14.74) .. (1868.61,-14.17)
 .. controls (1874.46,-13.60) and (1871.10,-13.60) .. (1876.38,-13.60)
 .. controls (1881.67,-13.60) and (1877.54,-13.31) .. (1882.24,-13.59)
 .. controls (1886.95,-13.88) and (1889.35,-13.97) .. (1890.98,-14.07)
 .. controls (1892.61,-14.16) and (1892.23,-14.07) .. (1895.01,-13.97)
 .. controls (1897.79,-13.87) and (1897.70,-13.68) .. (1900.19,-13.68)
 .. controls (1902.69,-13.68) and (1906.24,-14.16) .. (1907.10,-14.36)
 .. controls (1907.97,-14.55) and (1907.30,-14.26) .. (1910.65,-14.55)
 .. controls (1914.01,-14.84) and (1913.82,-14.84) .. (1916.89,-14.84)
 .. controls (1919.97,-14.84) and (1917.28,-14.65) .. (1921.79,-14.84)
 .. controls (1926.30,-15.04) and (1925.44,-15.13) .. (1929.95,-15.13)
 .. controls (1934.46,-15.13) and (1933.89,-15.13) .. (1938.11,-14.65)
 .. controls (1942.34,-14.17) and (1937.25,-13.78) .. (1943.97,-14.07)
 .. controls (1950.69,-14.36) and (1950.40,-15.03) .. (1953.95,-15.22)
 .. controls (1957.50,-15.41) and (1953.18,-15.51) .. (1959.23,-15.51)
 .. controls (1965.28,-15.51) and (1966.14,-15.60) .. (1969.98,-15.79)
 .. controls (1973.82,-15.99) and (1972.19,-16.56) .. (1976.80,-16.18)
 .. controls (1981.41,-15.79) and (1979.01,-16.08) .. (1982.94,-15.60)
 .. controls (1986.88,-15.12) and (1988.70,-14.93) .. (1989.38,-15.02)
 .. controls (1990.05,-15.12) and (1991.20,-15.41) .. (1996.38,-15.02)
 .. controls (2001.57,-14.64) and (2002.34,-14.93) .. (2008.10,-14.93)
 .. controls (2013.86,-14.93) and (2010.59,-14.64) .. (2016.26,-14.64)
 .. controls (2021.92,-14.64) and (2022.11,-14.93) .. (2027.30,-14.35)
 .. controls (2032.48,-13.77) and (2035.07,-14.16) .. (2042.08,-13.39)
 .. controls (2049.09,-12.62) and (2045.25,-12.33) .. (2051.20,-12.33)
 .. controls (2057.15,-12.33) and (2065.50,-11.56) .. (2067.33,-11.66)
 .. controls (2069.15,-11.76) and (2072.99,-12.81) .. (2078.85,-12.62)
 .. controls (2084.70,-12.43) and (2093.25,-13.29) .. (2097.76,-13.29)
 .. controls (2102.27,-13.29) and (2096.99,-13.39) .. (2103.71,-13.10)
 .. controls (2110.43,-12.82) and (2107.65,-13.01) .. (2114.65,-12.91)
 .. controls (2121.66,-12.82) and (2121.85,-12.62) .. (2124.54,-12.82)
 .. controls (2127.23,-13.01) and (2127.52,-13.78) .. (2131.36,-13.39)
 .. controls (2135.20,-13.01) and (2133.18,-12.43) .. (2139.04,-12.24)
 .. controls (2144.90,-12.05) and (2146.82,-11.95) .. (2147.78,-12.05)
 .. controls (2148.74,-12.14) and (2151.52,-12.05) .. (2156.42,-12.62)
 .. controls (2161.31,-13.20) and (2164.58,-14.35) .. (2167.45,-14.16)
 .. controls (2170.33,-13.96) and (2167.65,-13.77) .. (2174.65,-13.48)
 .. controls (2181.66,-13.20) and (2183.20,-12.81) .. (2186.94,-12.81)
 .. controls (2190.69,-12.81) and (2190.59,-12.62) .. (2195.97,-13.00)
 .. controls (2201.34,-13.39) and (2201.63,-14.16) .. (2204.80,-13.96)
 .. controls (2207.97,-13.77) and (2204.32,-13.87) .. (2210.17,-13.29)
 .. controls (2216.03,-12.72) and (2217.47,-12.72) .. (2220.93,-12.33)
 .. controls (2224.38,-11.95) and (2228.13,-13.10) .. (2233.02,-13.01)
 .. controls (2237.92,-12.91) and (2236.10,-13.39) .. (2243.58,-12.81)
 .. controls (2251.07,-12.24) and (2247.42,-12.33) .. (2254.82,-11.76)
 .. controls (2262.21,-11.18) and (2258.18,-11.38) .. (2264.80,-11.18)
 .. controls (2271.42,-10.99) and (2262.50,-11.18) .. (2274.21,-10.80)
 .. controls (2285.92,-10.42) and (2284.10,-10.42) .. (2289.09,-10.42)
 .. controls (2294.08,-10.42) and (2288.32,-10.04) .. (2294.75,-10.23)
 .. controls (2301.18,-10.42) and (2300.03,-10.33) .. (2302.72,-10.42)
),
1,((2302.72,-10.42)
 .. controls (2302.72,-10.42) and (2308.10,-10.81) .. (2313.66,-10.71)
 .. controls (2319.23,-10.62) and (2316.83,-10.42) .. (2322.30,-10.42)
 .. controls (2327.78,-10.42) and (2324.32,-11.19) .. (2330.08,-10.52)
 .. controls (2335.84,-9.85) and (2334.98,-9.75) .. (2339.68,-9.75)
 .. controls (2344.38,-9.75) and (2342.18,-9.27) .. (2348.61,-9.75)
 .. controls (2355.04,-10.23) and (2354.75,-11.48) .. (2360.90,-11.00)
 .. controls (2367.04,-10.52) and (2365.98,-10.33) .. (2370.59,-10.61)
 .. controls (2375.20,-10.90) and (2375.20,-11.19) .. (2377.79,-11.29)
 .. controls (2380.38,-11.38) and (2392.58,-12.73) .. (2394.98,-13.02)
 .. controls (2397.38,-13.30) and (2397.66,-13.40) .. (2401.98,-13.59)
 .. controls (2406.30,-13.78) and (2402.37,-13.59) .. (2409.28,-13.50)
 .. controls (2416.19,-13.40) and (2414.85,-13.40) .. (2421.86,-13.88)
 .. controls (2428.86,-14.36) and (2429.73,-15.32) .. (2433.66,-15.22)
 .. controls (2437.60,-15.13) and (2434.14,-14.46) .. (2440.48,-14.84)
 .. controls (2446.82,-15.22) and (2448.64,-15.90) .. (2454.98,-16.09)
 .. controls (2461.31,-16.28) and (2464.19,-16.47) .. (2467.36,-16.76)
 .. controls (2470.53,-17.05) and (2474.47,-16.95) .. (2480.13,-15.51)
 .. controls (2485.79,-14.06) and (2484.93,-13.39) .. (2490.30,-13.39)
 .. controls (2495.68,-13.39) and (2492.32,-14.83) .. (2498.46,-13.01)
 .. controls (2504.61,-11.18) and (2500.29,-12.14) .. (2507.39,-10.51)
 .. controls (2514.49,-8.88) and (2511.81,-9.26) .. (2517.09,-8.30)
 .. controls (2522.37,-7.34) and (2519.49,-8.02) .. (2525.44,-6.86)
 .. controls (2531.39,-5.71) and (2533.02,-5.42) .. (2535.71,-5.33)
 .. controls (2538.40,-5.23) and (2541.18,-4.94) .. (2544.54,-4.85)
 .. controls (2547.90,-4.75) and (2552.13,-3.79) .. (2552.13,-3.79)
),
1,((2558.27,18.00)
 .. controls (2558.27,18.00) and (2557.12,17.14) .. (2555.49,17.14)
 .. controls (2553.85,17.14) and (2548.77,17.33) .. (2547.90,17.33)
 .. controls (2547.04,17.33) and (2546.37,18.19) .. (2543.20,18.67)
 .. controls (2540.03,19.15) and (2537.05,19.15) .. (2534.75,19.15)
 .. controls (2532.45,19.15) and (2535.52,19.15) .. (2530.14,19.25)
 .. controls (2524.77,19.34) and (2527.07,18.96) .. (2522.65,19.54)
 .. controls (2518.24,20.11) and (2517.09,19.54) .. (2514.69,19.92)
 .. controls (2512.28,20.30) and (2512.76,20.69) .. (2509.12,20.88)
 .. controls (2505.47,21.07) and (2506.24,20.50) .. (2503.84,20.40)
 .. controls (2501.44,20.30) and (2497.98,20.59) .. (2495.19,20.30)
 .. controls (2492.41,20.02) and (2489.05,19.63) .. (2486.07,19.44)
 .. controls (2483.10,19.25) and (2485.88,19.73) .. (2480.98,19.92)
 .. controls (2476.09,20.11) and (2474.84,20.78) .. (2470.62,20.30)
 .. controls (2466.40,19.82) and (2468.80,21.54) .. (2462.36,20.97)
 .. controls (2455.93,20.39) and (2450.94,20.20) .. (2447.29,21.73)
 .. controls (2443.65,23.27) and (2434.82,25.09) .. (2432.51,26.15)
 .. controls (2430.21,27.21) and (2425.60,29.03) .. (2424.54,29.32)
 .. controls (2423.49,29.61) and (2420.99,30.85) .. (2418.02,30.37)
 .. controls (2415.04,29.89) and (2413.02,30.38) .. (2410.72,30.66)
 .. controls (2408.42,30.95) and (2402.75,30.28) .. (2401.12,29.90)
 .. controls (2399.49,29.51) and (2394.78,26.54) .. (2389.50,26.92)
 .. controls (2384.22,27.30) and (2380.38,28.46) .. (2376.64,27.40)
 .. controls (2372.90,26.34) and (2372.42,25.86) .. (2368.86,24.23)
 .. controls (2365.31,22.60) and (2363.20,20.30) .. (2360.51,18.86)
 .. controls (2357.82,17.42) and (2358.40,17.03) .. (2355.23,15.30)
 .. controls (2352.06,13.58) and (2351.10,12.90) .. (2349.28,12.23)
 .. controls (2347.46,11.56) and (2347.46,9.35) .. (2343.42,9.16)
 .. controls (2339.39,8.97) and (2333.82,7.72) .. (2331.04,7.82)
 .. controls (2328.26,7.91) and (2321.34,7.24) .. (2320.39,6.66)
 .. controls (2319.43,6.09) and (2320.19,5.32) .. (2316.93,4.55)
 .. controls (2313.67,3.78) and (2303.59,0.91) .. (2302.15,0.52)
 .. controls (2300.71,0.14) and (2295.23,-0.82) .. (2290.34,-1.30)
 .. controls (2285.44,-1.78) and (2283.23,-1.49) .. (2281.70,-1.59)
 .. controls (2280.16,-1.68) and (2274.30,-2.07) .. (2271.71,-2.26)
 .. controls (2269.12,-2.45) and (2265.38,-1.97) .. (2262.21,-1.97)
 .. controls (2259.04,-1.97) and (2258.37,-2.06) .. (2255.30,-1.20)
 .. controls (2252.22,-0.34) and (2245.60,-0.33) .. (2243.39,-0.43)
 .. controls (2241.18,-0.53) and (2239.36,0.24) .. (2236.86,0.82)
 .. controls (2234.37,1.39) and (2232.06,1.49) .. (2230.24,1.49)
 .. controls (2228.42,1.49) and (2223.90,1.59) .. (2222.37,1.78)
 .. controls (2220.83,1.97) and (2217.95,2.16) .. (2213.06,2.36)
 .. controls (2208.16,2.55) and (2207.68,2.93) .. (2204.61,3.22)
 .. controls (2201.54,3.51) and (2195.58,3.12) .. (2192.51,3.70)
 .. controls (2189.44,4.28) and (2191.36,3.70) .. (2186.46,3.80)
 .. controls (2181.57,3.89) and (2180.32,4.18) .. (2177.53,4.95)
 .. controls (2174.75,5.71) and (2172.83,6.96) .. (2171.77,7.63)
 .. controls (2170.72,8.31) and (2168.80,10.42) .. (2166.88,10.23)
 .. controls (2164.96,10.03) and (2162.94,10.03) .. (2161.79,10.03)
 .. controls (2160.64,10.03) and (2160.25,10.32) .. (2156.51,9.07)
 .. controls (2152.77,7.83) and (2151.90,7.06) .. (2150.08,6.77)
 .. controls (2148.25,6.48) and (2146.53,6.00) .. (2145.47,5.62)
),
1,((2145.47,5.62)
 .. controls (2145.47,5.62) and (2142.78,5.04) .. (2141.15,4.46)
 .. controls (2139.52,3.89) and (2137.41,3.31) .. (2136.35,3.02)
 .. controls (2135.29,2.74) and (2125.69,0.62) .. (2123.77,1.01)
 .. controls (2121.85,1.39) and (2125.21,1.78) .. (2117.73,1.30)
 .. controls (2110.24,0.82) and (2109.95,0.72) .. (2104.67,0.91)
 .. controls (2099.39,1.11) and (2097.47,1.01) .. (2096.03,0.92)
 .. controls (2094.59,0.82) and (2096.22,-0.24) .. (2090.27,1.59)
 .. controls (2084.32,3.41) and (2083.45,3.13) .. (2079.04,4.37)
 .. controls (2074.62,5.62) and (2075.97,5.62) .. (2069.73,6.48)
 .. controls (2063.49,7.35) and (2061.85,6.29) .. (2057.53,7.92)
 .. controls (2053.21,9.56) and (2055.13,9.08) .. (2051.10,10.13)
 .. controls (2047.07,11.19) and (2043.42,10.23) .. (2040.16,12.72)
 .. controls (2036.89,15.22) and (2036.51,14.74) .. (2033.25,17.62)
 .. controls (2029.98,20.50) and (2027.58,22.03) .. (2022.78,24.43)
 .. controls (2017.98,26.83) and (2011.36,28.37) .. (2006.84,29.62)
 .. controls (2002.33,30.86) and (2001.85,31.06) .. (1996.19,32.02)
 .. controls (1990.52,32.97) and (1991.68,33.45) .. (1987.07,33.65)
 .. controls (1982.46,33.84) and (1979.10,33.36) .. (1976.80,33.07)
 .. controls (1974.49,32.78) and (1970.36,32.68) .. (1968.35,31.92)
 .. controls (1966.33,31.15) and (1964.03,32.11) .. (1962.97,33.16)
 .. controls (1961.92,34.22) and (1958.94,36.04) .. (1958.36,38.15)
 .. controls (1957.79,40.27) and (1957.88,39.31) .. (1956.35,42.67)
 .. controls (1954.81,46.02) and (1957.98,46.12) .. (1952.32,47.75)
 .. controls (1946.65,49.38) and (1943.49,50.54) .. (1940.51,51.78)
 .. controls (1937.53,53.03) and (1936.09,53.42) .. (1933.21,54.76)
 .. controls (1930.33,56.10) and (1927.65,57.45) .. (1926.78,59.27)
 .. controls (1925.92,61.10) and (1922.85,68.01) .. (1922.46,69.83)
 .. controls (1922.08,71.66) and (1922.17,70.60) .. (1920.45,75.40)
 .. controls (1918.72,80.20) and (1918.05,84.04) .. (1915.65,86.82)
 .. controls (1913.25,89.61) and (1913.05,89.51) .. (1910.46,91.43)
 .. controls (1907.87,93.35) and (1907.39,94.12) .. (1902.88,95.08)
 .. controls (1898.37,96.04) and (1896.54,93.35) .. (1892.13,96.90)
 .. controls (1887.71,100.46) and (1883.68,101.80) .. (1880.22,104.87)
 .. controls (1876.76,107.94) and (1872.35,110.73) .. (1872.35,110.73)
),
1,((1872.35,110.73)
 .. controls (1872.35,110.73) and (1868.51,113.80) .. (1866.88,115.24)
 .. controls (1865.24,116.68) and (1866.30,116.87) .. (1862.17,118.41)
 .. controls (1858.04,119.94) and (1856.03,120.42) .. (1852.28,121.77)
 .. controls (1848.54,123.11) and (1847.67,123.98) .. (1842.87,125.32)
 .. controls (1838.07,126.66) and (1834.42,127.24) .. (1831.83,126.95)
 .. controls (1829.24,126.66) and (1826.65,127.62) .. (1825.02,125.80)
 .. controls (1823.38,123.98) and (1822.81,124.65) .. (1821.66,122.06)
 .. controls (1820.51,119.46) and (1819.45,118.60) .. (1818.87,115.72)
 .. controls (1818.30,112.84) and (1817.34,112.74) .. (1816.19,107.75)
 .. controls (1815.03,102.76) and (1815.13,103.24) .. (1813.79,98.44)
 .. controls (1812.44,93.64) and (1812.73,92.49) .. (1811.87,86.54)
 .. controls (1811.00,80.58) and (1811.68,77.61) .. (1811.29,75.21)
 .. controls (1810.91,72.81) and (1810.62,65.80) .. (1810.62,62.54)
 .. controls (1810.62,59.27) and (1810.33,55.63) .. (1809.85,52.75)
 .. controls (1809.37,49.87) and (1810.05,45.07) .. (1806.97,40.36)
 .. controls (1803.90,35.66) and (1803.52,36.62) .. (1802.17,32.49)
 .. controls (1800.83,28.36) and (1800.16,26.92) .. (1799.39,22.60)
 .. controls (1798.62,18.28) and (1798.43,16.36) .. (1797.56,13.29)
 .. controls (1796.70,10.21) and (1797.37,7.72) .. (1794.97,5.80)
 .. controls (1792.57,3.88) and (1792.77,3.30) .. (1789.79,2.44)
 .. controls (1786.81,1.57) and (1781.25,0.71) .. (1779.52,0.90)
),
1,((1779.52,0.90)
 .. controls (1779.52,0.90) and (1774.53,2.24) .. (1772.22,2.05)
 .. controls (1769.92,1.86) and (1762.82,2.91) .. (1759.94,3.49)
 .. controls (1757.06,4.07) and (1751.87,4.45) .. (1750.14,5.12)
 .. controls (1748.42,5.79) and (1745.06,7.04) .. (1741.98,7.71)
 .. controls (1738.91,8.39) and (1735.55,9.06) .. (1733.15,10.02)
 .. controls (1730.75,10.98) and (1726.24,12.23) .. (1723.46,13.57)
 .. controls (1720.67,14.91) and (1713.76,17.31) .. (1712.70,17.31)
 .. controls (1711.65,17.31) and (1709.34,16.93) .. (1700.61,18.47)
 .. controls (1691.87,20.00) and (1687.94,20.39) .. (1683.90,21.35)
 .. controls (1679.87,22.31) and (1681.31,22.21) .. (1675.07,23.27)
 .. controls (1668.83,24.32) and (1671.13,24.23) .. (1663.84,25.57)
 .. controls (1656.54,26.91) and (1651.07,27.49) .. (1646.36,28.45)
 .. controls (1641.66,29.41) and (1642.62,29.89) .. (1637.72,29.79)
 .. controls (1632.83,29.70) and (1629.56,28.93) .. (1621.79,27.20)
 .. controls (1614.01,25.47) and (1615.93,25.95) .. (1610.75,26.53)
 .. controls (1605.56,27.10) and (1598.56,29.31) .. (1595.87,29.98)
 .. controls (1593.18,30.65) and (1588.86,32.67) .. (1586.37,32.77)
 .. controls (1583.87,32.86) and (1584.06,33.44) .. (1580.61,32.38)
 .. controls (1577.15,31.33) and (1575.04,31.71) .. (1569.09,29.22)
 .. controls (1563.14,26.72) and (1559.39,25.57) .. (1557.57,24.80)
 .. controls (1555.74,24.04) and (1550.95,22.50) .. (1545.09,21.93)
 .. controls (1539.23,21.35) and (1536.06,21.35) .. (1531.74,20.68)
 .. controls (1527.42,20.01) and (1523.87,19.63) .. (1517.05,19.24)
 .. controls (1510.24,18.86) and (1512.16,18.38) .. (1506.88,19.33)
 .. controls (1501.60,20.29) and (1502.27,20.01) .. (1496.70,21.16)
 .. controls (1491.13,22.31) and (1486.24,23.65) .. (1486.24,23.65)
 .. controls (1486.24,23.65) and (1487.10,26.05) .. (1479.90,26.63)
 .. controls (1472.70,27.20) and (1472.32,25.28) .. (1465.12,27.39)
 .. controls (1457.92,29.50) and (1457.92,28.26) .. (1452.64,31.04)
 .. controls (1447.36,33.83) and (1444.48,35.94) .. (1442.75,37.28)
 .. controls (1441.02,38.63) and (1442.66,37.19) .. (1435.55,42.66)
 .. controls (1428.45,48.13) and (1426.72,49.19) .. (1425.95,49.48)
 .. controls (1425.18,49.76) and (1417.31,56.58) .. (1412.99,57.54)
 .. controls (1408.67,58.50) and (1403.49,60.52) .. (1398.78,59.94)
 .. controls (1394.08,59.37) and (1398.11,60.42) .. (1391.20,58.41)
 .. controls (1384.29,56.39) and (1382.27,55.34) .. (1377.95,53.22)
 .. controls (1373.63,51.11) and (1373.54,49.67) .. (1369.31,47.56)
),
1,((1369.31,47.56)
 .. controls (1369.31,47.56) and (1367.58,42.28) .. (1364.03,41.03)
 .. controls (1360.48,39.79) and (1360.09,39.31) .. (1356.45,38.06)
 .. controls (1352.80,36.81) and (1349.34,35.75) .. (1347.71,35.27)
 .. controls (1346.08,34.79) and (1346.08,34.31) .. (1341.47,33.35)
 .. controls (1336.86,32.39) and (1330.33,31.43) .. (1328.89,31.05)
 .. controls (1327.45,30.66) and (1324.48,29.61) .. (1322.94,29.13)
 .. controls (1321.41,28.65) and (1321.60,29.61) .. (1318.91,27.69)
 .. controls (1316.22,25.77) and (1312.48,23.65) .. (1310.65,22.60)
 .. controls (1308.83,21.54) and (1303.84,20.68) .. (1299.42,19.81)
 .. controls (1295.01,18.95) and (1288.29,17.03) .. (1285.12,16.26)
 .. controls (1281.95,15.49) and (1275.14,13.77) .. (1271.01,12.81)
 .. controls (1266.88,11.85) and (1267.94,12.23) .. (1263.71,11.08)
 .. controls (1259.49,9.93) and (1259.68,9.83) .. (1252.96,8.11)
 .. controls (1246.24,6.38) and (1247.49,7.05) .. (1244.13,5.71)
 .. controls (1240.77,4.37) and (1231.55,1.39) .. (1231.55,1.39)
 .. controls (1231.55,1.39) and (1228.39,-1.10) .. (1226.56,-1.78)
 .. controls (1224.74,-2.45) and (1222.05,-4.27) .. (1216.67,-6.48)
 .. controls (1211.30,-8.69) and (1212.06,-8.21) .. (1205.82,-10.70)
 .. controls (1199.58,-13.19) and (1200.45,-13.29) .. (1196.70,-14.35)
 .. controls (1192.96,-15.40) and (1188.73,-17.04) .. (1185.76,-17.90)
 .. controls (1182.78,-18.77) and (1183.64,-18.00) .. (1179.90,-19.25)
 .. controls (1176.16,-20.50) and (1175.58,-21.17) .. (1174.24,-20.69)
 .. controls (1172.89,-20.21) and (1172.41,-20.41) .. (1171.16,-19.35)
 .. controls (1169.92,-18.30) and (1170.49,-19.26) .. (1167.32,-15.61)
 .. controls (1164.16,-11.96) and (1163.48,-11.19) .. (1162.43,-9.94)
 .. controls (1161.37,-8.70) and (1160.12,-7.74) .. (1158.11,-6.97)
 .. controls (1156.09,-6.20) and (1155.13,-5.82) .. (1155.13,-5.82)
 .. controls (1155.13,-5.82) and (1154.56,-5.72) .. (1149.57,-3.99)
 .. controls (1144.58,-2.26) and (1141.12,-1.69) .. (1134.31,-0.63)
 .. controls (1127.49,0.43) and (1131.33,0.52) .. (1122.50,1.48)
 .. controls (1113.67,2.45) and (1113.38,2.93) .. (1107.23,2.73)
 .. controls (1101.09,2.54) and (1100.70,2.06) .. (1096.58,2.25)
 .. controls (1092.45,2.45) and (1090.91,3.02) .. (1087.65,2.83)
 .. controls (1084.38,2.64) and (1079.10,2.73) .. (1079.10,2.73)
),
1,((1079.10,2.73)
 .. controls (1079.10,2.73) and (1077.18,3.02) .. (1071.42,1.97)
 .. controls (1065.66,0.91) and (1064.51,2.35) .. (1057.41,0.53)
 .. controls (1050.30,-1.30) and (1041.57,-1.97) .. (1036.19,-3.22)
 .. controls (1030.81,-4.46) and (1030.05,-4.75) .. (1026.68,-5.33)
 .. controls (1023.32,-5.90) and (1023.23,-5.62) .. (1018.33,-6.58)
 .. controls (1013.44,-7.54) and (1005.76,-7.64) .. (1005.76,-7.64)
 .. controls (1005.76,-7.64) and (1003.26,-8.79) .. (996.45,-8.79)
 .. controls (989.63,-8.79) and (988.29,-8.03) .. (980.80,-8.31)
 .. controls (973.31,-8.60) and (966.59,-8.50) .. (961.22,-8.50)
 .. controls (955.84,-8.50) and (956.22,-9.07) .. (953.44,-8.21)
 .. controls (950.65,-7.34) and (951.52,-8.59) .. (947.10,-6.19)
 .. controls (942.68,-3.79) and (941.44,-2.35) .. (938.46,-0.05)
 .. controls (935.48,2.25) and (933.66,3.98) .. (931.55,6.67)
 .. controls (929.43,9.35) and (924.15,12.71) .. (920.99,14.44)
 .. controls (917.82,16.17) and (913.40,19.43) .. (911.58,20.10)
 .. controls (909.75,20.77) and (907.26,21.92) .. (903.51,22.50)
 .. controls (899.77,23.07) and (900.63,24.90) .. (896.70,22.79)
 .. controls (892.76,20.67) and (891.33,19.62) .. (887.87,17.70)
 .. controls (884.41,15.78) and (882.98,15.20) .. (877.41,12.52)
 .. controls (871.84,9.83) and (870.98,8.49) .. (868.48,6.66)
 .. controls (865.99,4.84) and (869.54,4.36) .. (863.68,1.77)
 .. controls (857.83,-0.82) and (854.08,-3.13) .. (848.23,-5.62)
 .. controls (842.37,-8.12) and (841.79,-8.79) .. (836.32,-10.32)
 .. controls (830.85,-11.86) and (830.75,-12.24) .. (827.10,-12.63)
 .. controls (823.46,-13.01) and (821.25,-12.53) .. (817.89,-13.02)
 .. controls (814.53,-13.50) and (811.93,-11.77) .. (803.77,-10.81)
 .. controls (795.61,-9.85) and (793.31,-8.80) .. (786.88,-8.80)
 .. controls (780.45,-8.80) and (777.66,-7.16) .. (772.10,-7.55)
 .. controls (766.53,-7.93) and (761.35,-8.22) .. (757.03,-8.89)
 .. controls (752.71,-9.56) and (750.60,-9.85) .. (745.61,-10.33)
 .. controls (740.61,-10.81) and (741.29,-11.19) .. (735.62,-10.90)
 .. controls (729.96,-10.61) and (732.36,-9.07) .. (724.29,-10.22)
 .. controls (716.23,-11.37) and (724.39,-9.55) .. (712.96,-11.56)
 .. controls (701.54,-13.58) and (699.43,-14.54) .. (693.38,-14.25)
 .. controls (687.33,-13.97) and (690.11,-13.10) .. (683.97,-13.49)
 .. controls (677.82,-13.88) and (676.58,-14.55) .. (672.26,-13.78)
 .. controls (667.94,-13.01) and (667.36,-12.63) .. (659.68,-11.67)
 .. controls (652.00,-10.71) and (655.46,-8.98) .. (644.22,-8.88)
 .. controls (632.99,-8.78) and (640.86,-7.63) .. (630.30,-8.40)
 .. controls (619.74,-9.17) and (613.50,-9.46) .. (613.02,-9.46)
),
1,((613.02,-9.46)
 .. controls (613.02,-9.46) and (612.83,-10.13) .. (608.51,-10.42)
 .. controls (604.19,-10.71) and (598.72,-10.23) .. (596.42,-10.90)
 .. controls (594.11,-11.57) and (589.60,-12.15) .. (586.53,-12.53)
 .. controls (583.46,-12.92) and (574.15,-14.17) .. (570.50,-14.74)
 .. controls (566.85,-15.32) and (561.19,-16.95) .. (557.83,-16.76)
 .. controls (554.47,-16.57) and (554.95,-16.66) .. (552.07,-16.47)
 .. controls (549.19,-16.28) and (539.30,-16.95) .. (536.71,-16.95)
 .. controls (534.12,-16.95) and (529.41,-15.90) .. (527.59,-16.76)
 .. controls (525.77,-17.63) and (519.33,-16.67) .. (514.15,-17.91)
 .. controls (508.97,-19.16) and (501.29,-20.40) .. (495.62,-20.50)
 .. controls (489.96,-20.59) and (483.91,-19.15) .. (477.86,-18.67)
 .. controls (471.81,-18.19) and (476.23,-19.05) .. (468.64,-18.28)
 .. controls (461.06,-17.52) and (455.68,-16.37) .. (448.48,-15.98)
 .. controls (441.28,-15.60) and (434.94,-15.51) .. (431.97,-15.80)
 .. controls (428.99,-16.08) and (426.69,-16.76) .. (422.66,-17.04)
 .. controls (418.62,-17.33) and (412.19,-16.47) .. (407.59,-16.09)
 .. controls (402.98,-15.70) and (397.60,-15.03) .. (393.28,-14.84)
 .. controls (388.96,-14.64) and (389.73,-15.51) .. (382.43,-13.97)
 .. controls (375.14,-12.44) and (374.75,-12.15) .. (368.13,-11.00)
 .. controls (361.51,-9.84) and (357.47,-8.60) .. (353.34,-8.50)
 .. controls (349.22,-8.40) and (347.68,-6.96) .. (343.84,-8.21)
 .. controls (340.00,-9.46) and (337.60,-9.75) .. (334.43,-11.00)
 .. controls (331.26,-12.25) and (321.28,-17.05) .. (317.82,-18.10)
 .. controls (314.37,-19.16) and (307.94,-22.14) .. (302.08,-24.06)
 .. controls (296.23,-25.98) and (294.21,-26.94) .. (288.26,-28.19)
 .. controls (282.31,-29.44) and (285.19,-28.67) .. (279.91,-29.92)
 .. controls (274.63,-31.16) and (271.75,-30.87) .. (268.96,-31.64)
 .. controls (266.18,-32.41) and (258.40,-34.71) .. (254.85,-36.25)
 .. controls (251.30,-37.78) and (250.63,-39.13) .. (244.96,-39.41)
 .. controls (239.30,-39.70) and (226.14,-39.32) .. (221.82,-39.42)
 .. controls (217.50,-39.52) and (217.02,-40.00) .. (213.95,-39.14)
 .. controls (210.88,-38.27) and (206.56,-36.93) .. (204.93,-36.93)
 .. controls (203.30,-36.93) and (208.00,-38.47) .. (198.31,-36.16)
 .. controls (188.61,-33.86) and (191.01,-34.05) .. (185.25,-33.66)
 .. controls (179.49,-33.28) and (181.22,-32.22) .. (173.25,-32.41)
 .. controls (165.28,-32.60) and (162.40,-33.08) .. (158.18,-34.04)
),
1,((158.18,-34.04)
 .. controls (158.18,-34.04) and (152.61,-35.38) .. (150.79,-35.29)
 .. controls (148.96,-35.19) and (144.73,-35.28) .. (141.37,-35.28)
 .. controls (138.01,-35.28) and (133.21,-35.00) .. (128.41,-34.23)
 .. controls (123.61,-33.47) and (124.28,-31.64) .. (116.60,-32.32)
 .. controls (108.92,-32.99) and (101.44,-32.04) .. (97.60,-32.33)
 .. controls (93.76,-32.61) and (84.35,-34.34) .. (83.87,-34.44)
 .. controls (83.39,-34.53) and (79.08,-37.80) .. (69.28,-37.79)
 .. controls (59.49,-37.79) and (54.02,-38.27) .. (48.84,-38.18)
 .. controls (43.65,-38.08) and (42.02,-36.93) .. (36.26,-36.83)
 .. controls (30.50,-36.73) and (24.84,-35.58) .. (22.15,-34.91)
 .. controls (19.46,-34.24) and (23.30,-33.28) .. (14.95,-32.60)
 .. controls (6.60,-31.93) and (2.47,-31.07) .. (-1.95,-30.40)
 .. controls (-6.36,-29.72) and (-8.48,-28.38) .. (-12.22,-28.38)
 .. controls (-15.96,-28.38) and (-14.81,-27.13) .. (-20.38,-28.38)
 .. controls (-25.95,-29.63) and (-30.27,-29.92) .. (-35.84,-31.26)
 .. controls (-41.41,-32.60) and (-43.04,-32.51) .. (-47.74,-33.47)
 .. controls (-52.45,-34.43) and (-61.37,-37.79) .. (-67.32,-38.18)
 .. controls (-73.28,-38.56) and (-76.44,-39.52) .. (-81.72,-39.81)
 .. controls (-87.00,-40.10) and (-86.91,-40.10) .. (-92.00,-40.87)
 .. controls (-97.08,-41.63) and (-96.70,-41.15) .. (-100.92,-41.73)
 .. controls (-105.15,-42.30) and (-111.29,-43.46) .. (-115.61,-42.97)
 .. controls (-119.93,-42.49) and (-120.12,-41.25) .. (-125.31,-41.44)
 .. controls (-130.49,-41.63) and (-134.04,-45.28) .. (-140.38,-45.09)
 .. controls (-146.72,-44.90) and (-149.41,-45.67) .. (-154.59,-45.86)
 .. controls (-159.77,-46.05) and (-159.20,-45.67) .. (-165.15,-45.86)
 .. controls (-171.10,-46.05) and (-172.93,-45.19) .. (-177.72,-44.23)
 .. controls (-182.52,-43.27) and (-184.44,-42.98) .. (-187.32,-41.93)
 .. controls (-190.20,-40.87) and (-197.88,-39.53) .. (-199.04,-39.53)
 .. controls (-200.19,-39.53) and (-206.14,-41.16) .. (-214.78,-41.35)
 .. controls (-223.42,-41.54) and (-228.32,-40.96) .. (-236.00,-40.10)
 .. controls (-243.68,-39.24) and (-241.37,-39.52) .. (-251.26,-38.85)
 .. controls (-261.15,-38.18) and (-263.45,-37.79) .. (-270.17,-38.85)
 .. controls (-276.90,-39.90) and (-275.55,-39.04) .. (-281.22,-40.00)
 .. controls (-286.88,-40.96) and (-293.41,-41.25) .. (-299.26,-40.29)
 .. controls (-305.12,-39.33) and (-305.50,-38.95) .. (-312.99,-38.56)
 .. controls (-320.47,-38.18) and (-324.60,-38.28) .. (-329.79,-39.14)
 .. controls (-334.97,-40.00) and (-333.43,-39.91) .. (-339.96,-41.06)
),
1,((-339.96,-41.06)
 .. controls (-339.96,-41.06) and (-343.70,-44.03) .. (-346.87,-44.51)
 .. controls (-350.04,-44.99) and (-358.97,-44.89) .. (-361.46,-44.41)
 .. controls (-363.96,-43.93) and (-366.84,-42.49) .. (-368.95,-41.53)
 .. controls (-371.07,-40.57) and (-382.97,-41.53) .. (-385.37,-42.59)
 .. controls (-387.77,-43.64) and (-389.98,-43.93) .. (-393.44,-45.76)
 .. controls (-396.89,-47.58) and (-403.81,-49.31) .. (-404.19,-49.60)
 .. controls (-404.57,-49.89) and (-413.40,-49.80) .. (-420.03,-50.37)
 .. controls (-426.65,-50.95) and (-428.00,-49.99) .. (-433.28,-50.76)
 .. controls (-438.55,-51.52) and (-434.81,-51.24) .. (-443.07,-51.91)
 .. controls (-451.32,-52.58) and (-456.12,-53.63) .. (-459.48,-53.63)
 .. controls (-462.84,-53.63) and (-463.32,-53.63) .. (-467.64,-52.77)
 .. controls (-471.96,-51.90) and (-478.78,-53.34) .. (-485.21,-52.38)
 .. controls (-491.64,-51.43) and (-492.41,-49.31) .. (-499.90,-50.27)
 .. controls (-507.39,-51.23) and (-509.02,-50.66) .. (-514.40,-51.33)
 .. controls (-519.77,-52.00) and (-520.54,-52.19) .. (-527.45,-52.39)
 .. controls (-534.36,-52.58) and (-535.23,-52.29) .. (-543.19,-53.15)
 .. controls (-551.16,-54.02) and (-552.70,-54.50) .. (-557.59,-55.36)
 .. controls (-562.49,-56.22) and (-568.73,-57.28) .. (-575.54,-57.56)
 .. controls (-582.36,-57.85) and (-583.61,-58.14) .. (-590.91,-59.10)
 .. controls (-598.20,-60.05) and (-599.84,-59.38) .. (-605.02,-60.05)
 .. controls (-610.20,-60.73) and (-608.38,-61.40) .. (-614.04,-60.73)
 .. controls (-619.71,-60.06) and (-627.58,-59.29) .. (-632.57,-58.24)
 .. controls (-637.56,-57.18) and (-641.21,-56.71) .. (-645.63,-55.46)
 .. controls (-650.04,-54.21) and (-651.48,-55.17) .. (-658.87,-53.44)
 .. controls (-666.27,-51.71) and (-669.05,-50.85) .. (-672.12,-50.37)
 .. controls (-675.20,-49.89) and (-675.68,-48.73) .. (-682.97,-49.41)
 .. controls (-690.27,-50.08) and (-695.74,-50.37) .. (-700.93,-50.46)
 .. controls (-706.11,-50.56) and (-713.21,-48.54) .. (-717.82,-49.31)
 .. controls (-722.43,-50.08) and (-726.27,-49.69) .. (-734.71,-47.96)
 .. controls (-743.16,-46.23) and (-739.51,-46.62) .. (-748.73,-45.17)
 .. controls (-757.95,-43.73) and (-754.59,-42.58) .. (-763.23,-43.25)
 .. controls (-771.87,-43.92) and (-769.08,-43.25) .. (-777.92,-44.31)
 .. controls (-786.75,-45.36) and (-798.17,-46.04) .. (-799.42,-46.04)
),
1,((-799.42,-46.04)
 .. controls (-799.42,-46.04) and (-804.99,-45.18) .. (-811.33,-45.47)
 .. controls (-817.66,-45.75) and (-814.69,-45.08) .. (-822.27,-45.85)
 .. controls (-829.85,-46.62) and (-830.81,-47.58) .. (-838.11,-47.00)
 .. controls (-845.40,-46.42) and (-847.13,-45.66) .. (-857.02,-46.04)
 .. controls (-866.91,-46.42) and (-875.45,-46.80) .. (-876.41,-46.80)
 .. controls (-877.37,-46.80) and (-878.14,-46.42) .. (-886.40,-45.55)
 .. controls (-894.65,-44.69) and (-893.02,-43.25) .. (-901.28,-44.31)
 .. controls (-909.53,-45.36) and (-910.88,-44.79) .. (-919.61,-46.03)
 .. controls (-928.35,-47.28) and (-930.56,-47.57) .. (-937.85,-48.43)
 .. controls (-945.15,-49.30) and (-951.01,-50.45) .. (-955.13,-50.74)
 .. controls (-959.26,-51.03) and (-960.70,-51.60) .. (-969.63,-52.66)
 .. controls (-978.56,-53.72) and (-983.55,-54.20) .. (-991.23,-55.06)
 .. controls (-998.91,-55.92) and (-996.51,-56.12) .. (-1006.01,-56.50)
 .. controls (-1015.52,-56.88) and (-1016.48,-57.08) .. (-1021.66,-56.12)
 .. controls (-1026.84,-55.16) and (-1028.67,-55.06) .. (-1034.43,-55.16)
 .. controls (-1040.19,-55.25) and (-1040.57,-54.48) .. (-1045.76,-55.06)
 .. controls (-1050.94,-55.63) and (-1046.43,-54.19) .. (-1058.81,-56.50)
 .. controls (-1071.20,-58.80) and (-1071.29,-58.60) .. (-1078.30,-58.99)
 .. controls (-1085.31,-59.37) and (-1088.19,-59.66) .. (-1097.31,-59.85)
 .. controls (-1106.43,-60.04) and (-1105.08,-57.93) .. (-1113.44,-59.37)
 .. controls (-1121.79,-60.81) and (-1128.51,-59.75) .. (-1130.33,-59.27)
 .. controls (-1132.16,-58.79) and (-1129.57,-58.12) .. (-1142.62,-58.31)
 .. controls (-1155.68,-58.50) and (-1154.82,-58.12) .. (-1164.13,-58.89)
 .. controls (-1173.44,-59.66) and (-1173.35,-58.89) .. (-1179.30,-59.85)
 .. controls (-1185.25,-60.82) and (-1191.11,-61.59) .. (-1193.31,-60.91)
 .. controls (-1195.52,-60.24) and (-1195.81,-59.38) .. (-1198.21,-59.67)
 .. controls (-1200.61,-59.95) and (-1207.81,-62.55) .. (-1214.43,-62.36)
 .. controls (-1221.06,-62.16) and (-1227.49,-61.59) .. (-1235.07,-61.59)
 .. controls (-1242.65,-61.59) and (-1242.08,-62.26) .. (-1248.32,-60.92)
 .. controls (-1254.56,-59.57) and (-1252.06,-57.84) .. (-1258.78,-59.19)
 .. controls (-1265.50,-60.53) and (-1268.96,-61.01) .. (-1273.28,-62.07)
 .. controls (-1277.60,-63.12) and (-1280.48,-64.18) .. (-1286.53,-64.95)
),
1,((-1286.53,-64.95)
 .. controls (-1286.53,-64.95) and (-1291.52,-65.23) .. (-1295.55,-65.52)
 .. controls (-1299.58,-65.81) and (-1302.08,-64.85) .. (-1308.03,-64.28)
 .. controls (-1313.98,-63.70) and (-1323.10,-62.07) .. (-1326.75,-60.92)
 .. controls (-1330.39,-59.77) and (-1328.38,-60.53) .. (-1333.66,-59.00)
 .. controls (-1338.94,-57.46) and (-1340.47,-54.29) .. (-1346.04,-53.91)
 .. controls (-1351.61,-53.52) and (-1351.23,-53.52) .. (-1357.95,-54.96)
 .. controls (-1364.67,-56.40) and (-1373.69,-59.18) .. (-1373.69,-59.18)
 .. controls (-1373.69,-59.18) and (-1373.31,-59.85) .. (-1378.88,-60.43)
 .. controls (-1384.45,-61.00) and (-1387.81,-62.15) .. (-1392.22,-61.77)
 .. controls (-1396.64,-61.39) and (-1395.29,-61.10) .. (-1399.81,-60.33)
 .. controls (-1404.32,-59.56) and (-1409.02,-58.70) .. (-1409.02,-58.70)
 .. controls (-1409.02,-58.70) and (-1420.93,-58.51) .. (-1423.52,-58.51)
 .. controls (-1426.11,-58.51) and (-1435.14,-57.46) .. (-1439.46,-57.17)
 .. controls (-1443.78,-56.88) and (-1443.39,-56.11) .. (-1449.92,-56.79)
 .. controls (-1456.45,-57.46) and (-1455.68,-57.46) .. (-1463.46,-57.94)
 .. controls (-1471.23,-58.42) and (-1473.92,-58.13) .. (-1478.43,-59.09)
 .. controls (-1482.94,-60.05) and (-1485.53,-60.44) .. (-1487.45,-61.01)
 .. controls (-1489.37,-61.59) and (-1493.50,-63.60) .. (-1498.40,-63.03)
 .. controls (-1503.29,-62.45) and (-1505.31,-62.54) .. (-1509.53,-62.26)
 .. controls (-1513.76,-61.97) and (-1517.40,-62.45) .. (-1520.19,-61.58)
 .. controls (-1522.97,-60.72) and (-1523.93,-61.29) .. (-1527.87,-60.43)
 .. controls (-1531.80,-59.56) and (-1532.00,-59.08) .. (-1534.59,-58.80)
 .. controls (-1537.18,-58.51) and (-1538.81,-57.93) .. (-1541.31,-57.64)
 .. controls (-1543.81,-57.35) and (-1544.48,-58.79) .. (-1551.58,-57.45)
 .. controls (-1558.69,-56.10) and (-1558.78,-55.34) .. (-1563.39,-54.95)
 .. controls (-1568.00,-54.57) and (-1567.71,-53.80) .. (-1570.59,-54.28)
 .. controls (-1573.47,-54.76) and (-1572.03,-55.24) .. (-1577.31,-55.53)
 .. controls (-1582.59,-55.81) and (-1584.51,-55.33) .. (-1587.78,-55.91)
 .. controls (-1591.04,-56.49) and (-1594.40,-56.30) .. (-1596.90,-57.16)
 .. controls (-1599.39,-58.02) and (-1604.19,-58.50) .. (-1607.65,-58.50)
 .. controls (-1611.10,-58.50) and (-1610.24,-58.60) .. (-1615.14,-59.08)
 .. controls (-1620.03,-59.56) and (-1615.04,-60.14) .. (-1622.62,-59.94)
 .. controls (-1630.21,-59.75) and (-1628.00,-60.04) .. (-1633.57,-59.27)
 .. controls (-1639.13,-58.50) and (-1635.49,-57.64) .. (-1641.34,-58.41)
 .. controls (-1647.20,-59.17) and (-1668.51,-61.57) .. (-1672.25,-61.57)
 .. controls (-1676.00,-61.57) and (-1676.28,-60.23) .. (-1680.70,-61.28)
 .. controls (-1685.12,-62.34) and (-1684.16,-61.76) .. (-1687.42,-62.82)
 .. controls (-1690.68,-63.87) and (-1691.07,-63.49) .. (-1693.08,-65.12)
 .. controls (-1695.10,-66.75) and (-1692.03,-66.66) .. (-1696.92,-67.81)
 .. controls (-1701.82,-68.96) and (-1700.57,-69.34) .. (-1703.55,-69.53)
 .. controls (-1706.52,-69.72) and (-1705.66,-70.30) .. (-1707.48,-69.05)
 .. controls (-1709.31,-67.80) and (-1709.31,-68.09) .. (-1711.52,-66.27)
 .. controls (-1713.72,-64.44) and (-1716.03,-61.95) .. (-1717.47,-61.56)
 .. controls (-1718.91,-61.18) and (-1725.73,-59.16) .. (-1729.47,-58.39)
 .. controls (-1733.22,-57.62) and (-1734.56,-57.62) .. (-1738.40,-57.34)
 .. controls (-1742.24,-57.05) and (-1741.18,-56.28) .. (-1745.79,-56.86)
 .. controls (-1750.40,-57.43) and (-1754.24,-58.20) .. (-1757.22,-58.49)
 .. controls (-1760.20,-58.78) and (-1761.54,-59.55) .. (-1765.00,-60.22)
 .. controls (-1768.45,-60.89) and (-1767.20,-59.84) .. (-1771.91,-61.18)
 .. controls (-1776.61,-62.53) and (-1781.41,-61.76) .. (-1784.00,-62.05)
 .. controls (-1786.59,-62.34) and (-1786.50,-62.24) .. (-1790.53,-62.34)
 .. controls (-1794.56,-62.44) and (-1793.89,-62.63) .. (-1799.55,-62.05)
 .. controls (-1805.22,-61.48) and (-1804.74,-61.38) .. (-1809.15,-60.81)
 .. controls (-1813.57,-60.23) and (-1814.24,-60.04) .. (-1816.74,-59.65)
 .. controls (-1819.24,-59.27) and (-1822.79,-58.89) .. (-1824.80,-58.31)
 .. controls (-1826.82,-57.73) and (-1825.09,-58.02) .. (-1830.85,-57.44)
 .. controls (-1836.61,-56.87) and (-1840.45,-56.48) .. (-1843.24,-56.20)
 .. controls (-1846.02,-55.91) and (-1842.47,-55.62) .. (-1848.33,-55.62)
 .. controls (-1854.18,-55.62) and (-1853.51,-54.95) .. (-1856.49,-55.62)
),
1,((-1856.49,-55.62)
 .. controls (-1856.49,-55.62) and (-1858.98,-55.72) .. (-1863.02,-56.10)
 .. controls (-1867.05,-56.49) and (-1868.97,-56.97) .. (-1874.73,-57.74)
 .. controls (-1880.49,-58.51) and (-1886.25,-58.89) .. (-1890.47,-59.18)
 .. controls (-1894.69,-59.46) and (-1892.20,-59.85) .. (-1897.67,-59.37)
 .. controls (-1903.14,-58.89) and (-1899.78,-58.02) .. (-1907.27,-58.89)
 .. controls (-1914.75,-59.75) and (-1918.78,-60.42) .. (-1922.43,-60.42)
 .. controls (-1926.08,-60.42) and (-1931.27,-60.52) .. (-1933.00,-60.61)
 .. controls (-1934.73,-60.71) and (-1935.21,-60.13) .. (-1938.76,-61.19)
 .. controls (-1942.31,-62.25) and (-1945.48,-63.30) .. (-1952.01,-64.17)
 .. controls (-1958.54,-65.03) and (-1957.49,-64.55) .. (-1961.42,-65.22)
 .. controls (-1965.36,-65.89) and (-1957.20,-64.74) .. (-1967.76,-66.37)
 .. controls (-1978.32,-68.00) and (-1974.29,-67.62) .. (-1981.10,-68.20)
 .. controls (-1987.92,-68.77) and (-1988.02,-68.87) .. (-1990.99,-68.77)
 .. controls (-1993.97,-68.68) and (-1995.60,-68.39) .. (-1998.10,-68.29)
 .. controls (-2000.59,-68.19) and (-1999.82,-69.44) .. (-2003.28,-68.87)
 .. controls (-2006.74,-68.29) and (-2007.13,-67.62) .. (-2010.68,-67.33)
 .. controls (-2014.23,-67.04) and (-2018.27,-67.13) .. (-2021.92,-66.46)
 .. controls (-2025.57,-65.79) and (-2021.34,-65.60) .. (-2028.35,-65.40)
 .. controls (-2035.36,-65.20) and (-2032.67,-65.11) .. (-2038.53,-64.72)
 .. controls (-2044.39,-64.33) and (-2045.63,-64.71) .. (-2050.25,-64.32)
 .. controls (-2054.86,-63.93) and (-2057.27,-62.87) .. (-2059.10,-63.16)
 .. controls (-2060.92,-63.45) and (-2067.17,-64.21) .. (-2073.04,-64.70)
 .. controls (-2078.90,-65.18) and (-2073.99,-65.47) .. (-2081.88,-65.29)
 .. controls (-2089.76,-65.11) and (-2088.71,-64.05) .. (-2095.81,-64.92)
 .. controls (-2102.90,-65.79) and (-2103.66,-66.27) .. (-2108.36,-65.99)
 .. controls (-2113.06,-65.70) and (-2110.28,-65.60) .. (-2116.52,-65.41)
 .. controls (-2122.76,-65.21) and (-2118.44,-65.79) .. (-2125.84,-64.93)
 .. controls (-2133.24,-64.06) and (-2133.05,-63.87) .. (-2138.81,-63.96)
 .. controls (-2144.58,-64.06) and (-2144.58,-63.77) .. (-2148.24,-63.10)
 .. controls (-2151.90,-62.43) and (-2153.93,-61.38) .. (-2156.24,-61.67)
 .. controls (-2158.54,-61.96) and (-2155.94,-62.15) .. (-2161.82,-61.96)
 .. controls (-2167.70,-61.77) and (-2169.02,-63.11) .. (-2173.19,-61.49)
 .. controls (-2177.37,-59.86) and (-2174.69,-58.99) .. (-2181.74,-58.71)
 .. controls (-2188.80,-58.42) and (-2186.47,-58.61) .. (-2191.23,-58.13)
 .. controls (-2196.00,-57.65) and (-2190.58,-57.17) .. (-2197.27,-57.56)
 .. controls (-2204.01,-57.94) and (-2199.92,-57.37) .. (-2205.77,-57.94)
 .. controls (-2211.66,-58.52) and (-2210.51,-57.95) .. (-2214.04,-58.43)
 .. controls (-2217.58,-58.91) and (-2213.47,-58.05) .. (-2219.01,-59.87)
 .. controls (-2224.56,-61.69) and (-2227.43,-63.32) .. (-2228.99,-63.90)
 .. controls (-2230.54,-64.47) and (-2231.53,-64.57) .. (-2235.63,-65.72)
 .. controls (-2239.71,-66.87) and (-2237.91,-66.97) .. (-2241.39,-67.07)
 .. controls (-2244.87,-67.17) and (-2246.16,-68.02) .. (-2250.25,-67.36)
 .. controls (-2254.40,-66.69) and (-2253.49,-67.26) .. (-2257.25,-66.13)
 .. controls (-2261.09,-64.97) and (-2261.09,-64.98) .. (-2263.02,-64.32)
 .. controls (-2264.98,-63.65) and (-2264.90,-64.31) .. (-2266.86,-62.61)
 .. controls (-2268.85,-60.89) and (-2271.09,-59.38) .. (-2272.50,-57.60)
 .. controls (-2273.93,-55.79) and (-2275.03,-56.28) .. (-2276.35,-49.89)
 .. controls (-2277.66,-43.54) and (-2278.90,-42.72) .. (-2279.84,-38.74)
 .. controls (-2280.77,-34.79) and (-2281.57,-33.87) .. (-2281.00,-28.83)
 .. controls (-2280.44,-23.80) and (-2280.84,-24.81) .. (-2279.64,-21.98)
 .. controls (-2278.44,-19.14) and (-2278.43,-20.49) .. (-2276.78,-14.94)
 .. controls (-2275.13,-9.39) and (-2274.76,-7.69) .. (-2274.38,-7.14)
 .. controls (-2274.00,-6.59) and (-2275.18,-8.68) .. (-2274.55,-3.65)
 .. controls (-2273.92,1.37) and (-2274.11,0.65) .. (-2273.74,3.86)
 .. controls (-2273.36,7.07) and (-2272.56,7.10) .. (-2274.50,10.63)
 .. controls (-2276.43,14.13) and (-2276.86,13.67) .. (-2277.54,16.00)
 .. controls (-2278.22,18.32) and (-2277.75,19.22) .. (-2277.70,21.40)
 .. controls (-2277.65,23.57) and (-2277.98,24.51) .. (-2278.15,25.28)
 .. controls (-2278.31,26.04) and (-2276.83,27.87) .. (-2278.41,30.36)
 .. controls (-2279.99,32.83) and (-2281.23,33.00) .. (-2282.01,35.68)
 .. controls (-2282.80,38.35) and (-2281.16,34.62) .. (-2283.57,39.66)
 .. controls (-2285.94,44.63) and (-2286.58,45.35) .. (-2286.95,45.99)
 .. controls (-2287.33,46.63) and (-2288.71,48.61) .. (-2289.06,49.93)
 .. controls (-2289.40,51.24) and (-2290.30,54.42) .. (-2291.93,56.60)
 .. controls (-2293.55,58.76) and (-2293.38,57.53) .. (-2294.54,60.24)
 .. controls (-2295.69,62.94) and (-2295.26,61.65) .. (-2296.86,65.04)
 .. controls (-2298.45,68.41) and (-2298.25,66.78) .. (-2299.38,69.86)
 .. controls (-2300.50,72.93) and (-2300.73,72.74) .. (-2300.57,74.82)
 .. controls (-2300.42,76.90) and (-2300.31,78.31) .. (-2300.31,78.31)
),
1,((-2409.78,50.14)
 .. controls (-2410.19,49.36) and (-2411.06,47.44) .. (-2411.87,45.25)
 .. controls (-2412.68,43.06) and (-2413.23,42.04) .. (-2413.92,40.04)
 .. controls (-2414.60,38.05) and (-2416.31,34.92) .. (-2417.08,33.21)
 .. controls (-2417.85,31.50) and (-2420.00,29.20) .. (-2421.58,26.43)
 .. controls (-2423.15,23.67) and (-2424.65,20.81) .. (-2427.06,17.63)
 .. controls (-2429.46,14.46) and (-2428.97,13.58) .. (-2432.25,10.32)
 .. controls (-2435.53,7.06) and (-2434.74,6.84) .. (-2439.03,3.61)
 .. controls (-2443.28,0.40) and (-2447.03,-1.47) .. (-2453.54,-5.84)
 .. controls (-2459.90,-10.11) and (-2461.81,-10.32) .. (-2467.12,-14.45)
 .. controls (-2472.23,-18.43) and (-2475.72,-21.70) .. (-2477.63,-23.49)
 .. controls (-2479.50,-25.23) and (-2479.03,-24.45) .. (-2483.52,-28.28)
 .. controls (-2487.88,-31.98) and (-2491.50,-35.92) .. (-2492.04,-36.89)
 .. controls (-2492.57,-37.86) and (-2495.35,-40.06) .. (-2497.50,-45.43)
 .. controls (-2499.64,-50.77) and (-2504.26,-62.08) .. (-2504.54,-65.01)
 .. controls (-2504.79,-67.77) and (-2504.82,-69.13) .. (-2504.78,-71.58)
 .. controls (-2504.74,-73.79) and (-2504.59,-72.66) .. (-2504.38,-76.40)
 .. controls (-2504.23,-79.01) and (-2503.90,-79.94) .. (-2503.57,-82.09)
 .. controls (-2503.17,-84.64) and (-2503.48,-84.03) .. (-2502.53,-86.33)
 .. controls (-2501.49,-88.86) and (-2499.93,-91.99) .. (-2499.03,-93.38)
 .. controls (-2498.10,-94.81) and (-2499.15,-93.59) .. (-2496.65,-96.69)
 .. controls (-2494.00,-99.96) and (-2489.06,-105.06) .. (-2485.98,-107.80)
 .. controls (-2482.75,-110.69) and (-2481.88,-111.63) .. (-2476.27,-115.39)
 .. controls (-2470.56,-119.22) and (-2467.08,-120.75) .. (-2464.31,-121.98)
 .. controls (-2461.58,-123.19) and (-2454.00,-126.14) .. (-2446.59,-126.92)
 .. controls (-2439.98,-127.62) and (-2438.40,-127.36) .. (-2434.78,-126.34)
 .. controls (-2431.96,-125.55) and (-2431.96,-125.76) .. (-2430.84,-124.24)
 .. controls (-2429.94,-123.01) and (-2429.63,-120.27) .. (-2430.89,-118.68)
 .. controls (-2432.42,-116.75) and (-2434.27,-115.93) .. (-2436.85,-114.32)
 .. controls (-2439.79,-112.49) and (-2444.54,-111.07) .. (-2446.06,-110.57)
 .. controls (-2447.61,-110.06) and (-2448.71,-109.97) .. (-2450.06,-109.61)
 .. controls (-2450.68,-109.44) and (-2455.83,-107.42) .. (-2456.91,-107.16)
 .. controls (-2457.90,-106.92) and (-2460.27,-106.39) .. (-2462.14,-106.23)
),
1,((-2462.51,-104.55)
 .. controls (-2462.51,-104.55) and (-2463.25,-104.71) .. (-2458.46,-104.63)
 .. controls (-2452.69,-104.54) and (-2452.94,-104.36) .. (-2448.45,-104.47)
 .. controls (-2444.05,-104.57) and (-2444.12,-104.49) .. (-2437.56,-104.48)
 .. controls (-2431.31,-104.46) and (-2429.08,-104.29) .. (-2426.23,-103.92)
 .. controls (-2423.49,-103.58) and (-2422.79,-103.69) .. (-2419.65,-103.01)
 .. controls (-2416.73,-102.39) and (-2419.12,-102.66) .. (-2414.36,-101.38)
 .. controls (-2410.45,-100.33) and (-2407.87,-98.05) .. (-2407.63,-97.98)
 .. controls (-2407.41,-97.91) and (-2408.35,-97.97) .. (-2407.21,-97.90)
 .. controls (-2406.77,-97.87) and (-2408.30,-95.75) .. (-2409.36,-95.52)
 .. controls (-2410.68,-95.22) and (-2409.54,-94.74) .. (-2414.72,-93.81)
 .. controls (-2422.14,-92.48) and (-2430.60,-92.01) .. (-2432.63,-92.32)
 .. controls (-2434.67,-92.64) and (-2439.56,-92.33) .. (-2442.70,-91.78)
 .. controls (-2445.84,-91.23) and (-2450.59,-89.89) .. (-2452.44,-90.22)
 .. controls (-2454.29,-90.54) and (-2453.89,-90.10) .. (-2459.91,-90.85)
 .. controls (-2465.94,-91.60) and (-2463.14,-90.88) .. (-2471.69,-91.45)
 .. controls (-2481.30,-92.09) and (-2483.49,-95.06) .. (-2480.79,-96.00)
 .. controls (-2475.97,-97.68) and (-2477.16,-95.56) .. (-2470.89,-95.75)
 .. controls (-2464.77,-95.94) and (-2463.28,-95.73) .. (-2482.79,-93.96)
 .. controls (-2490.14,-93.30) and (-2488.62,-93.44) .. (-2491.17,-93.29)
 .. controls (-2492.03,-93.25) and (-2485.78,-93.35) .. (-2488.33,-93.58)
 .. controls (-2492.18,-93.94) and (-2484.60,-93.77) .. (-2492.10,-93.37)
 .. controls (-2495.05,-93.21) and (-2489.79,-92.92) .. (-2485.50,-93.95)
 .. controls (-2484.83,-94.12) and (-2489.44,-90.13) .. (-2498.84,-95.71)
 .. controls (-2505.49,-99.65) and (-2483.73,-97.92) .. (-2492.80,-97.38)
 .. controls (-2511.11,-96.27) and (-2496.52,-96.57) .. (-2503.01,-96.71)
 .. controls (-2527.39,-97.24) and (-2533.68,-96.77) .. (-2532.23,-96.90)
 .. controls (-2526.75,-97.42) and (-2525.43,-97.69) .. (-2521.64,-97.48)
 .. controls (-2518.44,-97.30) and (-2515.85,-97.29) .. (-2512.70,-97.28)
 .. controls (-2510.43,-97.28) and (-2500.08,-99.91) .. (-2498.97,-98.63)
 .. controls (-2498.36,-97.92) and (-2507.32,-97.09) .. (-2499.23,-97.95)
 .. controls (-2491.20,-98.81) and (-2487.24,-99.00) .. (-2483.79,-99.01)
 .. controls (-2416.97,-99.19) and (-2333.69,-96.93) .. (-2326.71,-96.42)
 .. controls (-2323.13,-96.16) and (-2323.34,-96.23) .. (-2319.03,-96.81)
 .. controls (-2314.71,-97.38) and (-2313.35,-97.09) .. (-2309.12,-97.00)
 .. controls (-2304.90,-96.90) and (-2300.77,-96.71) .. (-2297.31,-97.00)
 .. controls (-2293.86,-97.28) and (-2292.70,-96.71) .. (-2290.01,-97.00)
 .. controls (-2287.33,-97.28) and (-2285.50,-96.42) .. (-2284.73,-96.71)
 .. controls (-2283.97,-97.00) and (-2278.30,-97.19) .. (-2277.92,-97.38)
),
1,((-2277.92,-97.38)
 .. controls (-2277.34,-97.57) and (-2275.52,-99.20) .. (-2273.31,-99.78)
 .. controls (-2271.11,-100.36) and (-2267.94,-100.65) .. (-2265.63,-100.65)
 .. controls (-2263.33,-100.65) and (-2262.08,-100.55) .. (-2259.01,-100.26)
 .. controls (-2255.93,-99.98) and (-2258.53,-99.69) .. (-2252.96,-100.17)
 .. controls (-2247.39,-100.65) and (-2252.19,-100.07) .. (-2244.99,-100.64)
 .. controls (-2237.79,-101.22) and (-2236.54,-101.41) .. (-2230.40,-102.08)
 .. controls (-2224.25,-102.75) and (-2220.99,-102.75) .. (-2220.99,-102.75)
 .. controls (-2220.99,-102.75) and (-2218.88,-102.74) .. (-2213.98,-102.17)
 .. controls (-2209.08,-101.59) and (-2208.60,-100.73) .. (-2204.96,-100.92)
 .. controls (-2201.31,-101.11) and (-2204.09,-101.30) .. (-2199.87,-101.11)
 .. controls (-2195.65,-100.92) and (-2196.61,-101.11) .. (-2192.00,-100.35)
 .. controls (-2187.39,-99.59) and (-2187.77,-99.20) .. (-2182.69,-98.92)
 .. controls (-2177.60,-98.63) and (-2176.44,-99.01) .. (-2172.80,-99.40)
 .. controls (-2169.15,-99.78) and (-2171.07,-99.78) .. (-2167.71,-99.78)
 .. controls (-2164.35,-99.78) and (-2161.18,-100.74) .. (-2160.02,-100.45)
 .. controls (-2158.87,-100.16) and (-2155.13,-100.64) .. (-2151.96,-100.54)
 .. controls (-2148.79,-100.44) and (-2150.81,-100.44) .. (-2148.03,-100.44)
 .. controls (-2145.24,-100.44) and (-2150.43,-100.82) .. (-2142.94,-100.35)
 .. controls (-2135.45,-99.87) and (-2136.22,-100.25) .. (-2132.48,-99.96)
 .. controls (-2128.73,-99.68) and (-2130.84,-99.48) .. (-2125.85,-99.68)
),
1,((-2125.85,-99.68)
 .. controls (-2123.45,-99.39) and (-2120.09,-100.45) .. (-2114.81,-100.26)
 .. controls (-2109.53,-100.07) and (-2113.09,-99.78) .. (-2108.38,-99.97)
 .. controls (-2103.68,-100.17) and (-2106.94,-100.17) .. (-2100.99,-100.45)
 .. controls (-2095.04,-100.74) and (-2095.52,-101.41) .. (-2090.81,-100.84)
 .. controls (-2086.11,-100.26) and (-2089.66,-99.78) .. (-2083.71,-100.45)
 .. controls (-2077.76,-101.12) and (-2076.32,-102.38) .. (-2070.36,-101.41)
 .. controls (-2064.41,-100.45) and (-2066.33,-99.38) .. (-2060.29,-99.96)
 .. controls (-2054.24,-100.54) and (-2054.91,-100.73) .. (-2049.92,-100.93)
 .. controls (-2044.93,-101.12) and (-2042.91,-101.31) .. (-2041.47,-100.64)
),
1,((-2041.47,-100.64)
 .. controls (-2041.47,-100.64) and (-2040.32,-100.35) .. (-2038.11,-100.16)
 .. controls (-2035.90,-99.97) and (-2035.52,-99.59) .. (-2031.58,-99.68)
 .. controls (-2027.65,-99.78) and (-2027.45,-100.45) .. (-2023.23,-100.16)
 .. controls (-2019.01,-99.88) and (-2018.33,-100.26) .. (-2012.57,-100.16)
 .. controls (-2006.81,-100.07) and (-2007.01,-99.97) .. (-2003.84,-99.97)
 .. controls (-2000.67,-99.97) and (-2000.96,-99.30) .. (-1997.12,-99.49)
 .. controls (-1993.28,-99.68) and (-1993.28,-99.40) .. (-1988.57,-100.26)
 .. controls (-1983.87,-101.12) and (-1983.10,-102.37) .. (-1980.22,-101.51)
 .. controls (-1977.34,-100.65) and (-1975.23,-99.40) .. (-1971.87,-98.73)
 .. controls (-1968.51,-98.05) and (-1969.57,-97.96) .. (-1965.44,-97.67)
 .. controls (-1961.31,-97.38) and (-1963.52,-97.67) .. (-1958.43,-97.19)
 .. controls (-1953.34,-96.71) and (-1954.30,-97.09) .. (-1949.50,-96.23)
 .. controls (-1944.70,-95.37) and (-1948.25,-96.52) .. (-1942.21,-94.60)
 .. controls (-1936.16,-92.68) and (-1940.48,-93.54) .. (-1933.85,-91.91)
 .. controls (-1927.23,-90.28) and (-1933.18,-90.86) .. (-1924.64,-90.18)
 .. controls (-1916.09,-89.51) and (-1919.07,-89.32) .. (-1914.85,-89.32)
 .. controls (-1910.62,-89.32) and (-1911.87,-89.13) .. (-1907.84,-89.61)
 .. controls (-1903.81,-90.09) and (-1908.03,-89.03) .. (-1900.45,-88.46)
 .. controls (-1892.86,-87.88) and (-1892.96,-87.88) .. (-1888.35,-88.55)
 .. controls (-1883.74,-89.23) and (-1885.76,-89.13) .. (-1880.29,-89.23)
 .. controls (-1874.81,-89.32) and (-1877.50,-89.32) .. (-1872.51,-89.32)
 .. controls (-1867.52,-89.32) and (-1868.86,-89.90) .. (-1864.54,-88.74)
 .. controls (-1860.22,-87.59) and (-1863.20,-87.11) .. (-1857.44,-87.11)
 .. controls (-1851.68,-87.11) and (-1853.60,-87.30) .. (-1849.09,-87.11)
 .. controls (-1844.57,-86.92) and (-1848.22,-86.24) .. (-1842.75,-86.72)
),
1,((-1840.16,-87.11)
 .. controls (-1834.01,-87.30) and (-1835.45,-87.30) .. (-1830.56,-87.20)
 .. controls (-1825.66,-87.11) and (-1833.15,-87.68) .. (-1823.45,-87.30)
 .. controls (-1813.76,-86.92) and (-1811.26,-87.59) .. (-1808.09,-86.34)
 .. controls (-1804.93,-85.09) and (-1806.65,-85.77) .. (-1801.85,-84.90)
 .. controls (-1797.05,-84.04) and (-1797.73,-84.23) .. (-1793.21,-83.85)
 .. controls (-1788.70,-83.46) and (-1784.19,-85.86) .. (-1779.01,-85.19)
 .. controls (-1773.82,-84.51) and (-1773.15,-84.13) .. (-1766.91,-84.22)
 .. controls (-1760.67,-84.32) and (-1761.24,-84.99) .. (-1754.04,-84.22)
 .. controls (-1746.84,-83.45) and (-1752.99,-84.70) .. (-1744.35,-83.45)
 .. controls (-1735.71,-82.20) and (-1736.96,-81.82) .. (-1734.17,-82.11)
 .. controls (-1731.39,-82.39) and (-1729.76,-83.35) .. (-1724.57,-83.74)
 .. controls (-1719.39,-84.12) and (-1715.45,-84.60) .. (-1712.29,-84.60)
 .. controls (-1709.12,-84.61) and (-1704.80,-85.47) .. (-1704.80,-85.47)
 .. controls (-1704.80,-85.47) and (-1704.99,-86.91) .. (-1697.98,-87.30)
 .. controls (-1690.97,-87.68) and (-1686.94,-89.31) .. (-1680.99,-89.22)
 .. controls (-1675.04,-89.12) and (-1677.73,-88.45) .. (-1669.95,-87.78)
 .. controls (-1662.17,-87.11) and (-1663.71,-87.01) .. (-1658.05,-86.63)
 .. controls (-1652.38,-86.25) and (-1651.90,-86.25) .. (-1647.29,-86.63)
 .. controls (-1642.69,-87.01) and (-1643.55,-87.40) .. (-1638.85,-87.21)
 .. controls (-1634.14,-87.02) and (-1625.98,-87.69) .. (-1624.93,-87.30)
),
1,((-1624.93,-87.30)
 .. controls (-1624.93,-87.30) and (-1623.39,-86.73) .. (-1618.30,-86.73)
 .. controls (-1613.21,-86.73) and (-1615.71,-87.02) .. (-1609.28,-86.25)
 .. controls (-1602.85,-85.48) and (-1604.86,-84.71) .. (-1597.95,-85.29)
 .. controls (-1591.04,-85.86) and (-1590.17,-85.48) .. (-1585.28,-85.96)
 .. controls (-1580.38,-86.44) and (-1580.29,-86.82) .. (-1575.29,-87.02)
 .. controls (-1570.30,-87.21) and (-1560.03,-87.59) .. (-1558.40,-87.78)
 .. controls (-1556.77,-87.98) and (-1559.84,-88.65) .. (-1555.52,-88.94)
 .. controls (-1551.20,-89.22) and (-1546.11,-90.95) .. (-1541.21,-91.63)
 .. controls (-1536.32,-92.30) and (-1537.18,-92.01) .. (-1531.52,-92.97)
 .. controls (-1525.86,-93.93) and (-1527.97,-93.64) .. (-1523.07,-94.22)
 .. controls (-1518.18,-94.80) and (-1517.70,-94.89) .. (-1514.34,-95.18)
 .. controls (-1510.98,-95.47) and (-1512.32,-95.76) .. (-1507.81,-95.66)
 .. controls (-1503.29,-95.57) and (-1505.60,-95.76) .. (-1500.22,-95.28)
 .. controls (-1494.85,-94.80) and (-1497.82,-96.34) .. (-1492.64,-94.32)
 .. controls (-1487.45,-92.31) and (-1487.65,-91.44) .. (-1485.05,-90.87)
 .. controls (-1482.46,-90.29) and (-1477.47,-89.62) .. (-1477.47,-89.62)
 .. controls (-1477.47,-89.62) and (-1479.39,-90.10) .. (-1471.61,-89.72)
 .. controls (-1463.84,-89.33) and (-1463.26,-89.14) .. (-1460.19,-88.85)
 .. controls (-1457.12,-88.56) and (-1458.84,-88.47) .. (-1454.14,-88.28)
 .. controls (-1449.44,-88.08) and (-1449.82,-87.70) .. (-1444.35,-87.51)
 .. controls (-1438.88,-87.31) and (-1443.96,-87.89) .. (-1437.24,-87.31)
 .. controls (-1430.52,-86.74) and (-1429.76,-87.12) .. (-1423.90,-87.02)
 .. controls (-1418.04,-86.93) and (-1418.43,-87.02) .. (-1409.88,-87.79)
 .. controls (-1401.34,-88.55) and (-1403.17,-88.94) .. (-1396.83,-89.03)
 .. controls (-1390.49,-89.13) and (-1392.99,-88.94) .. (-1387.42,-88.75)
 .. controls (-1381.85,-88.56) and (-1384.16,-88.36) .. (-1378.69,-88.17)
 .. controls (-1373.21,-87.98) and (-1370.53,-87.60) .. (-1366.59,-87.89)
 .. controls (-1362.65,-88.17) and (-1359.58,-88.65) .. (-1357.28,-88.08)
 .. controls (-1354.97,-87.50) and (-1358.43,-88.27) .. (-1353.73,-87.21)
 .. controls (-1349.02,-86.16) and (-1344.70,-86.74) .. (-1344.22,-86.64)
 .. controls (-1343.74,-86.55) and (-1337.50,-86.07) .. (-1334.33,-86.26)
 .. controls (-1331.17,-86.45) and (-1332.13,-86.93) .. (-1328.57,-86.74)
 .. controls (-1325.02,-86.55) and (-1327.13,-86.07) .. (-1322.24,-86.74)
 .. controls (-1317.34,-87.42) and (-1317.82,-87.32) .. (-1314.17,-87.61)
 .. controls (-1310.53,-87.89) and (-1313.89,-88.66) .. (-1307.93,-87.89)
 .. controls (-1301.98,-87.12) and (-1304.38,-87.03) .. (-1299.87,-87.22)
 .. controls (-1295.36,-87.41) and (-1296.03,-87.41) .. (-1292.00,-87.22)
 .. controls (-1287.97,-87.03) and (-1287.01,-86.64) .. (-1282.59,-86.74)
 .. controls (-1278.17,-86.83) and (-1275.77,-86.74) .. (-1274.33,-86.64)
 .. controls (-1272.89,-86.54) and (-1271.45,-86.16) .. (-1266.85,-86.45)
 .. controls (-1262.24,-86.74) and (-1258.11,-87.60) .. (-1254.56,-87.12)
 .. controls (-1251.01,-86.64) and (-1254.08,-86.93) .. (-1248.99,-86.26)
 .. controls (-1243.90,-85.59) and (-1245.44,-85.68) .. (-1242.17,-85.49)
 .. controls (-1238.91,-85.30) and (-1241.12,-85.68) .. (-1236.13,-85.11)
 .. controls (-1231.13,-84.53) and (-1232.67,-84.24) .. (-1228.83,-84.44)
 .. controls (-1224.99,-84.63) and (-1226.43,-84.82) .. (-1222.11,-84.92)
 .. controls (-1217.79,-85.01) and (-1218.37,-85.49) .. (-1215.29,-84.82)
 .. controls (-1212.22,-84.15) and (-1210.97,-86.35) .. (-1203.29,-85.78)
 .. controls (-1195.61,-85.20) and (-1195.90,-85.01) .. (-1192.83,-84.91)
 .. controls (-1189.76,-84.82) and (-1190.62,-84.91) .. (-1186.97,-84.53)
 .. controls (-1183.33,-84.15) and (-1185.82,-84.43) .. (-1181.79,-84.05)
 .. controls (-1177.76,-83.66) and (-1177.66,-83.38) .. (-1174.30,-83.47)
 .. controls (-1170.94,-83.57) and (-1165.85,-84.04) .. (-1163.26,-84.33)
));
draw_downscrap;
endfig;
beginfig(6);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2558.27,18.00)
 .. controls (2558.27,18.00) and (2557.12,17.14) .. (2555.49,17.14)
 .. controls (2553.85,17.14) and (2548.77,17.33) .. (2547.90,17.33)
 .. controls (2547.04,17.33) and (2546.37,18.19) .. (2543.20,18.67)
 .. controls (2540.03,19.15) and (2537.05,19.15) .. (2534.75,19.15)
 .. controls (2532.45,19.15) and (2535.52,19.15) .. (2530.14,19.25)
 .. controls (2524.77,19.34) and (2527.07,18.96) .. (2522.65,19.54)
 .. controls (2518.24,20.11) and (2517.09,19.54) .. (2514.69,19.92)
 .. controls (2512.28,20.30) and (2512.76,20.69) .. (2509.12,20.88)
 .. controls (2505.47,21.07) and (2506.24,20.50) .. (2503.84,20.40)
 .. controls (2501.44,20.30) and (2497.98,20.59) .. (2495.19,20.30)
 .. controls (2492.41,20.02) and (2489.05,19.63) .. (2486.07,19.44)
 .. controls (2483.10,19.25) and (2485.88,19.73) .. (2480.98,19.92)
 .. controls (2476.09,20.11) and (2474.84,20.78) .. (2470.62,20.30)
 .. controls (2466.40,19.82) and (2468.80,21.54) .. (2462.36,20.97)
 .. controls (2455.93,20.39) and (2450.94,20.20) .. (2447.29,21.73)
 .. controls (2443.65,23.27) and (2434.82,25.09) .. (2432.51,26.15)
 .. controls (2430.21,27.21) and (2425.60,29.03) .. (2424.54,29.32)
 .. controls (2423.49,29.61) and (2420.99,30.85) .. (2418.02,30.37)
 .. controls (2415.04,29.89) and (2413.02,30.38) .. (2410.72,30.66)
 .. controls (2408.42,30.95) and (2402.75,30.28) .. (2401.12,29.90)
 .. controls (2399.49,29.51) and (2394.78,26.54) .. (2389.50,26.92)
 .. controls (2384.22,27.30) and (2380.38,28.46) .. (2376.64,27.40)
 .. controls (2372.90,26.34) and (2372.42,25.86) .. (2368.86,24.23)
 .. controls (2365.31,22.60) and (2363.20,20.30) .. (2360.51,18.86)
 .. controls (2357.82,17.42) and (2358.40,17.03) .. (2355.23,15.30)
 .. controls (2352.06,13.58) and (2351.10,12.90) .. (2349.28,12.23)
 .. controls (2347.46,11.56) and (2347.46,9.35) .. (2343.42,9.16)
 .. controls (2339.39,8.97) and (2333.82,7.72) .. (2331.04,7.82)
 .. controls (2328.26,7.91) and (2321.34,7.24) .. (2320.39,6.66)
 .. controls (2319.43,6.09) and (2320.19,5.32) .. (2316.93,4.55)
 .. controls (2313.67,3.78) and (2303.59,0.91) .. (2302.15,0.52)
 .. controls (2300.71,0.14) and (2295.23,-0.82) .. (2290.34,-1.30)
 .. controls (2285.44,-1.78) and (2283.23,-1.49) .. (2281.70,-1.59)
 .. controls (2280.16,-1.68) and (2274.30,-2.07) .. (2271.71,-2.26)
 .. controls (2269.12,-2.45) and (2265.38,-1.97) .. (2262.21,-1.97)
 .. controls (2259.04,-1.97) and (2258.37,-2.06) .. (2255.30,-1.20)
 .. controls (2252.22,-0.34) and (2245.60,-0.33) .. (2243.39,-0.43)
 .. controls (2241.18,-0.53) and (2239.36,0.24) .. (2236.86,0.82)
 .. controls (2234.37,1.39) and (2232.06,1.49) .. (2230.24,1.49)
 .. controls (2228.42,1.49) and (2223.90,1.59) .. (2222.37,1.78)
 .. controls (2220.83,1.97) and (2217.95,2.16) .. (2213.06,2.36)
 .. controls (2208.16,2.55) and (2207.68,2.93) .. (2204.61,3.22)
 .. controls (2201.54,3.51) and (2195.58,3.12) .. (2192.51,3.70)
 .. controls (2189.44,4.28) and (2191.36,3.70) .. (2186.46,3.80)
 .. controls (2181.57,3.89) and (2180.32,4.18) .. (2177.53,4.95)
 .. controls (2174.75,5.71) and (2172.83,6.96) .. (2171.77,7.63)
 .. controls (2170.72,8.31) and (2168.80,10.42) .. (2166.88,10.23)
 .. controls (2164.96,10.03) and (2162.94,10.03) .. (2161.79,10.03)
 .. controls (2160.64,10.03) and (2160.25,10.32) .. (2156.51,9.07)
 .. controls (2152.77,7.83) and (2151.90,7.06) .. (2150.08,6.77)
 .. controls (2148.25,6.48) and (2146.53,6.00) .. (2145.47,5.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2145.47,5.62)
 .. controls (2145.47,5.62) and (2142.78,5.04) .. (2141.15,4.46)
 .. controls (2139.52,3.89) and (2137.41,3.31) .. (2136.35,3.02)
 .. controls (2135.29,2.74) and (2125.69,0.62) .. (2123.77,1.01)
 .. controls (2121.85,1.39) and (2125.21,1.78) .. (2117.73,1.30)
 .. controls (2110.24,0.82) and (2109.95,0.72) .. (2104.67,0.91)
 .. controls (2099.39,1.11) and (2097.47,1.01) .. (2096.03,0.92)
 .. controls (2094.59,0.82) and (2096.22,-0.24) .. (2090.27,1.59)
 .. controls (2084.32,3.41) and (2083.45,3.13) .. (2079.04,4.37)
 .. controls (2074.62,5.62) and (2075.97,5.62) .. (2069.73,6.48)
 .. controls (2063.49,7.35) and (2061.85,6.29) .. (2057.53,7.92)
 .. controls (2053.21,9.56) and (2055.13,9.08) .. (2051.10,10.13)
 .. controls (2047.07,11.19) and (2043.42,10.23) .. (2040.16,12.72)
 .. controls (2036.89,15.22) and (2036.51,14.74) .. (2033.25,17.62)
 .. controls (2029.98,20.50) and (2027.58,22.03) .. (2022.78,24.43)
 .. controls (2017.98,26.83) and (2011.36,28.37) .. (2006.84,29.62)
 .. controls (2002.33,30.86) and (2001.85,31.06) .. (1996.19,32.02)
 .. controls (1990.52,32.97) and (1991.68,33.45) .. (1987.07,33.65)
 .. controls (1982.46,33.84) and (1979.10,33.36) .. (1976.80,33.07)
 .. controls (1974.49,32.78) and (1970.36,32.68) .. (1968.35,31.92)
 .. controls (1966.33,31.15) and (1964.03,32.11) .. (1962.97,33.16)
 .. controls (1961.92,34.22) and (1958.94,36.04) .. (1958.36,38.15)
 .. controls (1957.79,40.27) and (1957.88,39.31) .. (1956.35,42.67)
 .. controls (1954.81,46.02) and (1957.98,46.12) .. (1952.32,47.75)
 .. controls (1946.65,49.38) and (1943.49,50.54) .. (1940.51,51.78)
 .. controls (1937.53,53.03) and (1936.09,53.42) .. (1933.21,54.76)
 .. controls (1930.33,56.10) and (1927.65,57.45) .. (1926.78,59.27)
 .. controls (1925.92,61.10) and (1922.85,68.01) .. (1922.46,69.83)
 .. controls (1922.08,71.66) and (1922.17,70.60) .. (1920.45,75.40)
 .. controls (1918.72,80.20) and (1918.05,84.04) .. (1915.65,86.82)
 .. controls (1913.25,89.61) and (1913.05,89.51) .. (1910.46,91.43)
 .. controls (1907.87,93.35) and (1907.39,94.12) .. (1902.88,95.08)
 .. controls (1898.37,96.04) and (1896.54,93.35) .. (1892.13,96.90)
 .. controls (1887.71,100.46) and (1883.68,101.80) .. (1880.22,104.87)
 .. controls (1876.76,107.94) and (1872.35,110.73) .. (1872.35,110.73)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1872.35,110.73)
 .. controls (1872.35,110.73) and (1868.51,113.80) .. (1866.88,115.24)
 .. controls (1865.24,116.68) and (1866.30,116.87) .. (1862.17,118.41)
 .. controls (1858.04,119.94) and (1856.03,120.42) .. (1852.28,121.77)
 .. controls (1848.54,123.11) and (1847.67,123.98) .. (1842.87,125.32)
 .. controls (1838.07,126.66) and (1834.42,127.24) .. (1831.83,126.95)
 .. controls (1829.24,126.66) and (1826.65,127.62) .. (1825.02,125.80)
 .. controls (1823.38,123.98) and (1822.81,124.65) .. (1821.66,122.06)
 .. controls (1820.51,119.46) and (1819.45,118.60) .. (1818.87,115.72)
 .. controls (1818.30,112.84) and (1817.34,112.74) .. (1816.19,107.75)
 .. controls (1815.03,102.76) and (1815.13,103.24) .. (1813.79,98.44)
 .. controls (1812.44,93.64) and (1812.73,92.49) .. (1811.87,86.54)
 .. controls (1811.00,80.58) and (1811.68,77.61) .. (1811.29,75.21)
 .. controls (1810.91,72.81) and (1810.62,65.80) .. (1810.62,62.54)
 .. controls (1810.62,59.27) and (1810.33,55.63) .. (1809.85,52.75)
 .. controls (1809.37,49.87) and (1810.05,45.07) .. (1806.97,40.36)
 .. controls (1803.90,35.66) and (1803.52,36.62) .. (1802.17,32.49)
 .. controls (1800.83,28.36) and (1800.16,26.92) .. (1799.39,22.60)
 .. controls (1798.62,18.28) and (1798.43,16.36) .. (1797.56,13.29)
 .. controls (1796.70,10.21) and (1797.37,7.72) .. (1794.97,5.80)
 .. controls (1792.57,3.88) and (1792.77,3.30) .. (1789.79,2.44)
 .. controls (1786.81,1.57) and (1781.25,0.71) .. (1779.52,0.90)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1779.52,0.90)
 .. controls (1779.52,0.90) and (1774.53,2.24) .. (1772.22,2.05)
 .. controls (1769.92,1.86) and (1762.82,2.91) .. (1759.94,3.49)
 .. controls (1757.06,4.07) and (1751.87,4.45) .. (1750.14,5.12)
 .. controls (1748.42,5.79) and (1745.06,7.04) .. (1741.98,7.71)
 .. controls (1738.91,8.39) and (1735.55,9.06) .. (1733.15,10.02)
 .. controls (1730.75,10.98) and (1726.24,12.23) .. (1723.46,13.57)
 .. controls (1720.67,14.91) and (1713.76,17.31) .. (1712.70,17.31)
 .. controls (1711.65,17.31) and (1709.34,16.93) .. (1700.61,18.47)
 .. controls (1691.87,20.00) and (1687.94,20.39) .. (1683.90,21.35)
 .. controls (1679.87,22.31) and (1681.31,22.21) .. (1675.07,23.27)
 .. controls (1668.83,24.32) and (1671.13,24.23) .. (1663.84,25.57)
 .. controls (1656.54,26.91) and (1651.07,27.49) .. (1646.36,28.45)
 .. controls (1641.66,29.41) and (1642.62,29.89) .. (1637.72,29.79)
 .. controls (1632.83,29.70) and (1629.56,28.93) .. (1621.79,27.20)
 .. controls (1614.01,25.47) and (1615.93,25.95) .. (1610.75,26.53)
 .. controls (1605.56,27.10) and (1598.56,29.31) .. (1595.87,29.98)
 .. controls (1593.18,30.65) and (1588.86,32.67) .. (1586.37,32.77)
 .. controls (1583.87,32.86) and (1584.06,33.44) .. (1580.61,32.38)
 .. controls (1577.15,31.33) and (1575.04,31.71) .. (1569.09,29.22)
 .. controls (1563.14,26.72) and (1559.39,25.57) .. (1557.57,24.80)
 .. controls (1555.74,24.04) and (1550.95,22.50) .. (1545.09,21.93)
 .. controls (1539.23,21.35) and (1536.06,21.35) .. (1531.74,20.68)
 .. controls (1527.42,20.01) and (1523.87,19.63) .. (1517.05,19.24)
 .. controls (1510.24,18.86) and (1512.16,18.38) .. (1506.88,19.33)
 .. controls (1501.60,20.29) and (1502.27,20.01) .. (1496.70,21.16)
 .. controls (1491.13,22.31) and (1486.24,23.65) .. (1486.24,23.65)
 .. controls (1486.24,23.65) and (1487.10,26.05) .. (1479.90,26.63)
 .. controls (1472.70,27.20) and (1472.32,25.28) .. (1465.12,27.39)
 .. controls (1457.92,29.50) and (1457.92,28.26) .. (1452.64,31.04)
 .. controls (1447.36,33.83) and (1444.48,35.94) .. (1442.75,37.28)
 .. controls (1441.02,38.63) and (1442.66,37.19) .. (1435.55,42.66)
 .. controls (1428.45,48.13) and (1426.72,49.19) .. (1425.95,49.48)
 .. controls (1425.18,49.76) and (1417.31,56.58) .. (1412.99,57.54)
 .. controls (1408.67,58.50) and (1403.49,60.52) .. (1398.78,59.94)
 .. controls (1394.08,59.37) and (1398.11,60.42) .. (1391.20,58.41)
 .. controls (1384.29,56.39) and (1382.27,55.34) .. (1377.95,53.22)
 .. controls (1373.63,51.11) and (1373.54,49.67) .. (1369.31,47.56)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1369.31,47.56)
 .. controls (1369.31,47.56) and (1367.58,42.28) .. (1364.03,41.03)
 .. controls (1360.48,39.79) and (1360.09,39.31) .. (1356.45,38.06)
 .. controls (1352.80,36.81) and (1349.34,35.75) .. (1347.71,35.27)
 .. controls (1346.08,34.79) and (1346.08,34.31) .. (1341.47,33.35)
 .. controls (1336.86,32.39) and (1330.33,31.43) .. (1328.89,31.05)
 .. controls (1327.45,30.66) and (1324.48,29.61) .. (1322.94,29.13)
 .. controls (1321.41,28.65) and (1321.60,29.61) .. (1318.91,27.69)
 .. controls (1316.22,25.77) and (1312.48,23.65) .. (1310.65,22.60)
 .. controls (1308.83,21.54) and (1303.84,20.68) .. (1299.42,19.81)
 .. controls (1295.01,18.95) and (1288.29,17.03) .. (1285.12,16.26)
 .. controls (1281.95,15.49) and (1275.14,13.77) .. (1271.01,12.81)
 .. controls (1266.88,11.85) and (1267.94,12.23) .. (1263.71,11.08)
 .. controls (1259.49,9.93) and (1259.68,9.83) .. (1252.96,8.11)
 .. controls (1246.24,6.38) and (1247.49,7.05) .. (1244.13,5.71)
 .. controls (1240.77,4.37) and (1231.55,1.39) .. (1231.55,1.39)
 .. controls (1231.55,1.39) and (1228.39,-1.10) .. (1226.56,-1.78)
 .. controls (1224.74,-2.45) and (1222.05,-4.27) .. (1216.67,-6.48)
 .. controls (1211.30,-8.69) and (1212.06,-8.21) .. (1205.82,-10.70)
 .. controls (1199.58,-13.19) and (1200.45,-13.29) .. (1196.70,-14.35)
 .. controls (1192.96,-15.40) and (1188.73,-17.04) .. (1185.76,-17.90)
 .. controls (1182.78,-18.77) and (1183.64,-18.00) .. (1179.90,-19.25)
 .. controls (1176.16,-20.50) and (1175.58,-21.17) .. (1174.24,-20.69)
 .. controls (1172.89,-20.21) and (1172.41,-20.41) .. (1171.16,-19.35)
 .. controls (1169.92,-18.30) and (1170.49,-19.26) .. (1167.32,-15.61)
 .. controls (1164.16,-11.96) and (1163.48,-11.19) .. (1162.43,-9.94)
 .. controls (1161.37,-8.70) and (1160.12,-7.74) .. (1158.11,-6.97)
 .. controls (1156.09,-6.20) and (1155.13,-5.82) .. (1155.13,-5.82)
 .. controls (1155.13,-5.82) and (1154.56,-5.72) .. (1149.57,-3.99)
 .. controls (1144.58,-2.26) and (1141.12,-1.69) .. (1134.31,-0.63)
 .. controls (1127.49,0.43) and (1131.33,0.52) .. (1122.50,1.48)
 .. controls (1113.67,2.45) and (1113.38,2.93) .. (1107.23,2.73)
 .. controls (1101.09,2.54) and (1100.70,2.06) .. (1096.58,2.25)
 .. controls (1092.45,2.45) and (1090.91,3.02) .. (1087.65,2.83)
 .. controls (1084.38,2.64) and (1079.10,2.73) .. (1079.10,2.73)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1079.10,2.73)
 .. controls (1079.10,2.73) and (1077.18,3.02) .. (1071.42,1.97)
 .. controls (1065.66,0.91) and (1064.51,2.35) .. (1057.41,0.53)
 .. controls (1050.30,-1.30) and (1041.57,-1.97) .. (1036.19,-3.22)
 .. controls (1030.81,-4.46) and (1030.05,-4.75) .. (1026.68,-5.33)
 .. controls (1023.32,-5.90) and (1023.23,-5.62) .. (1018.33,-6.58)
 .. controls (1013.44,-7.54) and (1005.76,-7.64) .. (1005.76,-7.64)
 .. controls (1005.76,-7.64) and (1003.26,-8.79) .. (996.45,-8.79)
 .. controls (989.63,-8.79) and (988.29,-8.03) .. (980.80,-8.31)
 .. controls (973.31,-8.60) and (966.59,-8.50) .. (961.22,-8.50)
 .. controls (955.84,-8.50) and (956.22,-9.07) .. (953.44,-8.21)
 .. controls (950.65,-7.34) and (951.52,-8.59) .. (947.10,-6.19)
 .. controls (942.68,-3.79) and (941.44,-2.35) .. (938.46,-0.05)
 .. controls (935.48,2.25) and (933.66,3.98) .. (931.55,6.67)
 .. controls (929.43,9.35) and (924.15,12.71) .. (920.99,14.44)
 .. controls (917.82,16.17) and (913.40,19.43) .. (911.58,20.10)
 .. controls (909.75,20.77) and (907.26,21.92) .. (903.51,22.50)
 .. controls (899.77,23.07) and (900.63,24.90) .. (896.70,22.79)
 .. controls (892.76,20.67) and (891.33,19.62) .. (887.87,17.70)
 .. controls (884.41,15.78) and (882.98,15.20) .. (877.41,12.52)
 .. controls (871.84,9.83) and (870.98,8.49) .. (868.48,6.66)
 .. controls (865.99,4.84) and (869.54,4.36) .. (863.68,1.77)
 .. controls (857.83,-0.82) and (854.08,-3.13) .. (848.23,-5.62)
 .. controls (842.37,-8.12) and (841.79,-8.79) .. (836.32,-10.32)
 .. controls (830.85,-11.86) and (830.75,-12.24) .. (827.10,-12.63)
 .. controls (823.46,-13.01) and (821.25,-12.53) .. (817.89,-13.02)
 .. controls (814.53,-13.50) and (811.93,-11.77) .. (803.77,-10.81)
 .. controls (795.61,-9.85) and (793.31,-8.80) .. (786.88,-8.80)
 .. controls (780.45,-8.80) and (777.66,-7.16) .. (772.10,-7.55)
 .. controls (766.53,-7.93) and (761.35,-8.22) .. (757.03,-8.89)
 .. controls (752.71,-9.56) and (750.60,-9.85) .. (745.61,-10.33)
 .. controls (740.61,-10.81) and (741.29,-11.19) .. (735.62,-10.90)
 .. controls (729.96,-10.61) and (732.36,-9.07) .. (724.29,-10.22)
 .. controls (716.23,-11.37) and (724.39,-9.55) .. (712.96,-11.56)
 .. controls (701.54,-13.58) and (699.43,-14.54) .. (693.38,-14.25)
 .. controls (687.33,-13.97) and (690.11,-13.10) .. (683.97,-13.49)
 .. controls (677.82,-13.88) and (676.58,-14.55) .. (672.26,-13.78)
 .. controls (667.94,-13.01) and (667.36,-12.63) .. (659.68,-11.67)
 .. controls (652.00,-10.71) and (655.46,-8.98) .. (644.22,-8.88)
 .. controls (632.99,-8.78) and (640.86,-7.63) .. (630.30,-8.40)
 .. controls (619.74,-9.17) and (613.50,-9.46) .. (613.02,-9.46)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((613.02,-9.46)
 .. controls (613.02,-9.46) and (612.83,-10.13) .. (608.51,-10.42)
 .. controls (604.19,-10.71) and (598.72,-10.23) .. (596.42,-10.90)
 .. controls (594.11,-11.57) and (589.60,-12.15) .. (586.53,-12.53)
 .. controls (583.46,-12.92) and (574.15,-14.17) .. (570.50,-14.74)
 .. controls (566.85,-15.32) and (561.19,-16.95) .. (557.83,-16.76)
 .. controls (554.47,-16.57) and (554.95,-16.66) .. (552.07,-16.47)
 .. controls (549.19,-16.28) and (539.30,-16.95) .. (536.71,-16.95)
 .. controls (534.12,-16.95) and (529.41,-15.90) .. (527.59,-16.76)
 .. controls (525.77,-17.63) and (519.33,-16.67) .. (514.15,-17.91)
 .. controls (508.97,-19.16) and (501.29,-20.40) .. (495.62,-20.50)
 .. controls (489.96,-20.59) and (483.91,-19.15) .. (477.86,-18.67)
 .. controls (471.81,-18.19) and (476.23,-19.05) .. (468.64,-18.28)
 .. controls (461.06,-17.52) and (455.68,-16.37) .. (448.48,-15.98)
 .. controls (441.28,-15.60) and (434.94,-15.51) .. (431.97,-15.80)
 .. controls (428.99,-16.08) and (426.69,-16.76) .. (422.66,-17.04)
 .. controls (418.62,-17.33) and (412.19,-16.47) .. (407.59,-16.09)
 .. controls (402.98,-15.70) and (397.60,-15.03) .. (393.28,-14.84)
 .. controls (388.96,-14.64) and (389.73,-15.51) .. (382.43,-13.97)
 .. controls (375.14,-12.44) and (374.75,-12.15) .. (368.13,-11.00)
 .. controls (361.51,-9.84) and (357.47,-8.60) .. (353.34,-8.50)
 .. controls (349.22,-8.40) and (347.68,-6.96) .. (343.84,-8.21)
 .. controls (340.00,-9.46) and (337.60,-9.75) .. (334.43,-11.00)
 .. controls (331.26,-12.25) and (321.28,-17.05) .. (317.82,-18.10)
 .. controls (314.37,-19.16) and (307.94,-22.14) .. (302.08,-24.06)
 .. controls (296.23,-25.98) and (294.21,-26.94) .. (288.26,-28.19)
 .. controls (282.31,-29.44) and (285.19,-28.67) .. (279.91,-29.92)
 .. controls (274.63,-31.16) and (271.75,-30.87) .. (268.96,-31.64)
 .. controls (266.18,-32.41) and (258.40,-34.71) .. (254.85,-36.25)
 .. controls (251.30,-37.78) and (250.63,-39.13) .. (244.96,-39.41)
 .. controls (239.30,-39.70) and (226.14,-39.32) .. (221.82,-39.42)
 .. controls (217.50,-39.52) and (217.02,-40.00) .. (213.95,-39.14)
 .. controls (210.88,-38.27) and (206.56,-36.93) .. (204.93,-36.93)
 .. controls (203.30,-36.93) and (208.00,-38.47) .. (198.31,-36.16)
 .. controls (188.61,-33.86) and (191.01,-34.05) .. (185.25,-33.66)
 .. controls (179.49,-33.28) and (181.22,-32.22) .. (173.25,-32.41)
 .. controls (165.28,-32.60) and (162.40,-33.08) .. (158.18,-34.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((158.18,-34.04)
 .. controls (158.18,-34.04) and (152.61,-35.38) .. (150.79,-35.29)
 .. controls (148.96,-35.19) and (144.73,-35.28) .. (141.37,-35.28)
 .. controls (138.01,-35.28) and (133.21,-35.00) .. (128.41,-34.23)
 .. controls (123.61,-33.47) and (124.28,-31.64) .. (116.60,-32.32)
 .. controls (108.92,-32.99) and (101.44,-32.04) .. (97.60,-32.33)
 .. controls (93.76,-32.61) and (84.35,-34.34) .. (83.87,-34.44)
 .. controls (83.39,-34.53) and (79.08,-37.80) .. (69.28,-37.79)
 .. controls (59.49,-37.79) and (54.02,-38.27) .. (48.84,-38.18)
 .. controls (43.65,-38.08) and (42.02,-36.93) .. (36.26,-36.83)
 .. controls (30.50,-36.73) and (24.84,-35.58) .. (22.15,-34.91)
 .. controls (19.46,-34.24) and (23.30,-33.28) .. (14.95,-32.60)
 .. controls (6.60,-31.93) and (2.47,-31.07) .. (-1.95,-30.40)
 .. controls (-6.36,-29.72) and (-8.48,-28.38) .. (-12.22,-28.38)
 .. controls (-15.96,-28.38) and (-14.81,-27.13) .. (-20.38,-28.38)
 .. controls (-25.95,-29.63) and (-30.27,-29.92) .. (-35.84,-31.26)
 .. controls (-41.41,-32.60) and (-43.04,-32.51) .. (-47.74,-33.47)
 .. controls (-52.45,-34.43) and (-61.37,-37.79) .. (-67.32,-38.18)
 .. controls (-73.28,-38.56) and (-76.44,-39.52) .. (-81.72,-39.81)
 .. controls (-87.00,-40.10) and (-86.91,-40.10) .. (-92.00,-40.87)
 .. controls (-97.08,-41.63) and (-96.70,-41.15) .. (-100.92,-41.73)
 .. controls (-105.15,-42.30) and (-111.29,-43.46) .. (-115.61,-42.97)
 .. controls (-119.93,-42.49) and (-120.12,-41.25) .. (-125.31,-41.44)
 .. controls (-130.49,-41.63) and (-134.04,-45.28) .. (-140.38,-45.09)
 .. controls (-146.72,-44.90) and (-149.41,-45.67) .. (-154.59,-45.86)
 .. controls (-159.77,-46.05) and (-159.20,-45.67) .. (-165.15,-45.86)
 .. controls (-171.10,-46.05) and (-172.93,-45.19) .. (-177.72,-44.23)
 .. controls (-182.52,-43.27) and (-184.44,-42.98) .. (-187.32,-41.93)
 .. controls (-190.20,-40.87) and (-197.88,-39.53) .. (-199.04,-39.53)
 .. controls (-200.19,-39.53) and (-206.14,-41.16) .. (-214.78,-41.35)
 .. controls (-223.42,-41.54) and (-228.32,-40.96) .. (-236.00,-40.10)
 .. controls (-243.68,-39.24) and (-241.37,-39.52) .. (-251.26,-38.85)
 .. controls (-261.15,-38.18) and (-263.45,-37.79) .. (-270.17,-38.85)
 .. controls (-276.90,-39.90) and (-275.55,-39.04) .. (-281.22,-40.00)
 .. controls (-286.88,-40.96) and (-293.41,-41.25) .. (-299.26,-40.29)
 .. controls (-305.12,-39.33) and (-305.50,-38.95) .. (-312.99,-38.56)
 .. controls (-320.47,-38.18) and (-324.60,-38.28) .. (-329.79,-39.14)
 .. controls (-334.97,-40.00) and (-333.43,-39.91) .. (-339.96,-41.06)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-339.96,-41.06)
 .. controls (-339.96,-41.06) and (-343.70,-44.03) .. (-346.87,-44.51)
 .. controls (-350.04,-44.99) and (-358.97,-44.89) .. (-361.46,-44.41)
 .. controls (-363.96,-43.93) and (-366.84,-42.49) .. (-368.95,-41.53)
 .. controls (-371.07,-40.57) and (-382.97,-41.53) .. (-385.37,-42.59)
 .. controls (-387.77,-43.64) and (-389.98,-43.93) .. (-393.44,-45.76)
 .. controls (-396.89,-47.58) and (-403.81,-49.31) .. (-404.19,-49.60)
 .. controls (-404.57,-49.89) and (-413.40,-49.80) .. (-420.03,-50.37)
 .. controls (-426.65,-50.95) and (-428.00,-49.99) .. (-433.28,-50.76)
 .. controls (-438.55,-51.52) and (-434.81,-51.24) .. (-443.07,-51.91)
 .. controls (-451.32,-52.58) and (-456.12,-53.63) .. (-459.48,-53.63)
 .. controls (-462.84,-53.63) and (-463.32,-53.63) .. (-467.64,-52.77)
 .. controls (-471.96,-51.90) and (-478.78,-53.34) .. (-485.21,-52.38)
 .. controls (-491.64,-51.43) and (-492.41,-49.31) .. (-499.90,-50.27)
 .. controls (-507.39,-51.23) and (-509.02,-50.66) .. (-514.40,-51.33)
 .. controls (-519.77,-52.00) and (-520.54,-52.19) .. (-527.45,-52.39)
 .. controls (-534.36,-52.58) and (-535.23,-52.29) .. (-543.19,-53.15)
 .. controls (-551.16,-54.02) and (-552.70,-54.50) .. (-557.59,-55.36)
 .. controls (-562.49,-56.22) and (-568.73,-57.28) .. (-575.54,-57.56)
 .. controls (-582.36,-57.85) and (-583.61,-58.14) .. (-590.91,-59.10)
 .. controls (-598.20,-60.05) and (-599.84,-59.38) .. (-605.02,-60.05)
 .. controls (-610.20,-60.73) and (-608.38,-61.40) .. (-614.04,-60.73)
 .. controls (-619.71,-60.06) and (-627.58,-59.29) .. (-632.57,-58.24)
 .. controls (-637.56,-57.18) and (-641.21,-56.71) .. (-645.63,-55.46)
 .. controls (-650.04,-54.21) and (-651.48,-55.17) .. (-658.87,-53.44)
 .. controls (-666.27,-51.71) and (-669.05,-50.85) .. (-672.12,-50.37)
 .. controls (-675.20,-49.89) and (-675.68,-48.73) .. (-682.97,-49.41)
 .. controls (-690.27,-50.08) and (-695.74,-50.37) .. (-700.93,-50.46)
 .. controls (-706.11,-50.56) and (-713.21,-48.54) .. (-717.82,-49.31)
 .. controls (-722.43,-50.08) and (-726.27,-49.69) .. (-734.71,-47.96)
 .. controls (-743.16,-46.23) and (-739.51,-46.62) .. (-748.73,-45.17)
 .. controls (-757.95,-43.73) and (-754.59,-42.58) .. (-763.23,-43.25)
 .. controls (-771.87,-43.92) and (-769.08,-43.25) .. (-777.92,-44.31)
 .. controls (-786.75,-45.36) and (-798.17,-46.04) .. (-799.42,-46.04)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-799.42,-46.04)
 .. controls (-799.42,-46.04) and (-804.99,-45.18) .. (-811.33,-45.47)
 .. controls (-817.66,-45.75) and (-814.69,-45.08) .. (-822.27,-45.85)
 .. controls (-829.85,-46.62) and (-830.81,-47.58) .. (-838.11,-47.00)
 .. controls (-845.40,-46.42) and (-847.13,-45.66) .. (-857.02,-46.04)
 .. controls (-866.91,-46.42) and (-875.45,-46.80) .. (-876.41,-46.80)
 .. controls (-877.37,-46.80) and (-878.14,-46.42) .. (-886.40,-45.55)
 .. controls (-894.65,-44.69) and (-893.02,-43.25) .. (-901.28,-44.31)
 .. controls (-909.53,-45.36) and (-910.88,-44.79) .. (-919.61,-46.03)
 .. controls (-928.35,-47.28) and (-930.56,-47.57) .. (-937.85,-48.43)
 .. controls (-945.15,-49.30) and (-951.01,-50.45) .. (-955.13,-50.74)
 .. controls (-959.26,-51.03) and (-960.70,-51.60) .. (-969.63,-52.66)
 .. controls (-978.56,-53.72) and (-983.55,-54.20) .. (-991.23,-55.06)
 .. controls (-998.91,-55.92) and (-996.51,-56.12) .. (-1006.01,-56.50)
 .. controls (-1015.52,-56.88) and (-1016.48,-57.08) .. (-1021.66,-56.12)
 .. controls (-1026.84,-55.16) and (-1028.67,-55.06) .. (-1034.43,-55.16)
 .. controls (-1040.19,-55.25) and (-1040.57,-54.48) .. (-1045.76,-55.06)
 .. controls (-1050.94,-55.63) and (-1046.43,-54.19) .. (-1058.81,-56.50)
 .. controls (-1071.20,-58.80) and (-1071.29,-58.60) .. (-1078.30,-58.99)
 .. controls (-1085.31,-59.37) and (-1088.19,-59.66) .. (-1097.31,-59.85)
 .. controls (-1106.43,-60.04) and (-1105.08,-57.93) .. (-1113.44,-59.37)
 .. controls (-1121.79,-60.81) and (-1128.51,-59.75) .. (-1130.33,-59.27)
 .. controls (-1132.16,-58.79) and (-1129.57,-58.12) .. (-1142.62,-58.31)
 .. controls (-1155.68,-58.50) and (-1154.82,-58.12) .. (-1164.13,-58.89)
 .. controls (-1173.44,-59.66) and (-1173.35,-58.89) .. (-1179.30,-59.85)
 .. controls (-1185.25,-60.82) and (-1191.11,-61.59) .. (-1193.31,-60.91)
 .. controls (-1195.52,-60.24) and (-1195.81,-59.38) .. (-1198.21,-59.67)
 .. controls (-1200.61,-59.95) and (-1207.81,-62.55) .. (-1214.43,-62.36)
 .. controls (-1221.06,-62.16) and (-1227.49,-61.59) .. (-1235.07,-61.59)
 .. controls (-1242.65,-61.59) and (-1242.08,-62.26) .. (-1248.32,-60.92)
 .. controls (-1254.56,-59.57) and (-1252.06,-57.84) .. (-1258.78,-59.19)
 .. controls (-1265.50,-60.53) and (-1268.96,-61.01) .. (-1273.28,-62.07)
 .. controls (-1277.60,-63.12) and (-1280.48,-64.18) .. (-1286.53,-64.95)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1286.53,-64.95)
 .. controls (-1286.53,-64.95) and (-1291.52,-65.23) .. (-1295.55,-65.52)
 .. controls (-1299.58,-65.81) and (-1302.08,-64.85) .. (-1308.03,-64.28)
 .. controls (-1313.98,-63.70) and (-1323.10,-62.07) .. (-1326.75,-60.92)
 .. controls (-1330.39,-59.77) and (-1328.38,-60.53) .. (-1333.66,-59.00)
 .. controls (-1338.94,-57.46) and (-1340.47,-54.29) .. (-1346.04,-53.91)
 .. controls (-1351.61,-53.52) and (-1351.23,-53.52) .. (-1357.95,-54.96)
 .. controls (-1364.67,-56.40) and (-1373.69,-59.18) .. (-1373.69,-59.18)
 .. controls (-1373.69,-59.18) and (-1373.31,-59.85) .. (-1378.88,-60.43)
 .. controls (-1384.45,-61.00) and (-1387.81,-62.15) .. (-1392.22,-61.77)
 .. controls (-1396.64,-61.39) and (-1395.29,-61.10) .. (-1399.81,-60.33)
 .. controls (-1404.32,-59.56) and (-1409.02,-58.70) .. (-1409.02,-58.70)
 .. controls (-1409.02,-58.70) and (-1420.93,-58.51) .. (-1423.52,-58.51)
 .. controls (-1426.11,-58.51) and (-1435.14,-57.46) .. (-1439.46,-57.17)
 .. controls (-1443.78,-56.88) and (-1443.39,-56.11) .. (-1449.92,-56.79)
 .. controls (-1456.45,-57.46) and (-1455.68,-57.46) .. (-1463.46,-57.94)
 .. controls (-1471.23,-58.42) and (-1473.92,-58.13) .. (-1478.43,-59.09)
 .. controls (-1482.94,-60.05) and (-1485.53,-60.44) .. (-1487.45,-61.01)
 .. controls (-1489.37,-61.59) and (-1493.50,-63.60) .. (-1498.40,-63.03)
 .. controls (-1503.29,-62.45) and (-1505.31,-62.54) .. (-1509.53,-62.26)
 .. controls (-1513.76,-61.97) and (-1517.40,-62.45) .. (-1520.19,-61.58)
 .. controls (-1522.97,-60.72) and (-1523.93,-61.29) .. (-1527.87,-60.43)
 .. controls (-1531.80,-59.56) and (-1532.00,-59.08) .. (-1534.59,-58.80)
 .. controls (-1537.18,-58.51) and (-1538.81,-57.93) .. (-1541.31,-57.64)
 .. controls (-1543.81,-57.35) and (-1544.48,-58.79) .. (-1551.58,-57.45)
 .. controls (-1558.69,-56.10) and (-1558.78,-55.34) .. (-1563.39,-54.95)
 .. controls (-1568.00,-54.57) and (-1567.71,-53.80) .. (-1570.59,-54.28)
 .. controls (-1573.47,-54.76) and (-1572.03,-55.24) .. (-1577.31,-55.53)
 .. controls (-1582.59,-55.81) and (-1584.51,-55.33) .. (-1587.78,-55.91)
 .. controls (-1591.04,-56.49) and (-1594.40,-56.30) .. (-1596.90,-57.16)
 .. controls (-1599.39,-58.02) and (-1604.19,-58.50) .. (-1607.65,-58.50)
 .. controls (-1611.10,-58.50) and (-1610.24,-58.60) .. (-1615.14,-59.08)
 .. controls (-1620.03,-59.56) and (-1615.04,-60.14) .. (-1622.62,-59.94)
 .. controls (-1630.21,-59.75) and (-1628.00,-60.04) .. (-1633.57,-59.27)
 .. controls (-1639.13,-58.50) and (-1635.49,-57.64) .. (-1641.34,-58.41)
 .. controls (-1647.20,-59.17) and (-1668.51,-61.57) .. (-1672.25,-61.57)
 .. controls (-1676.00,-61.57) and (-1676.28,-60.23) .. (-1680.70,-61.28)
 .. controls (-1685.12,-62.34) and (-1684.16,-61.76) .. (-1687.42,-62.82)
 .. controls (-1690.68,-63.87) and (-1691.07,-63.49) .. (-1693.08,-65.12)
 .. controls (-1695.10,-66.75) and (-1692.03,-66.66) .. (-1696.92,-67.81)
 .. controls (-1701.82,-68.96) and (-1700.57,-69.34) .. (-1703.55,-69.53)
 .. controls (-1706.52,-69.72) and (-1705.66,-70.30) .. (-1707.48,-69.05)
 .. controls (-1709.31,-67.80) and (-1709.31,-68.09) .. (-1711.52,-66.27)
 .. controls (-1713.72,-64.44) and (-1716.03,-61.95) .. (-1717.47,-61.56)
 .. controls (-1718.91,-61.18) and (-1725.73,-59.16) .. (-1729.47,-58.39)
 .. controls (-1733.22,-57.62) and (-1734.56,-57.62) .. (-1738.40,-57.34)
 .. controls (-1742.24,-57.05) and (-1741.18,-56.28) .. (-1745.79,-56.86)
 .. controls (-1750.40,-57.43) and (-1754.24,-58.20) .. (-1757.22,-58.49)
 .. controls (-1760.20,-58.78) and (-1761.54,-59.55) .. (-1765.00,-60.22)
 .. controls (-1768.45,-60.89) and (-1767.20,-59.84) .. (-1771.91,-61.18)
 .. controls (-1776.61,-62.53) and (-1781.41,-61.76) .. (-1784.00,-62.05)
 .. controls (-1786.59,-62.34) and (-1786.50,-62.24) .. (-1790.53,-62.34)
 .. controls (-1794.56,-62.44) and (-1793.89,-62.63) .. (-1799.55,-62.05)
 .. controls (-1805.22,-61.48) and (-1804.74,-61.38) .. (-1809.15,-60.81)
 .. controls (-1813.57,-60.23) and (-1814.24,-60.04) .. (-1816.74,-59.65)
 .. controls (-1819.24,-59.27) and (-1822.79,-58.89) .. (-1824.80,-58.31)
 .. controls (-1826.82,-57.73) and (-1825.09,-58.02) .. (-1830.85,-57.44)
 .. controls (-1836.61,-56.87) and (-1840.45,-56.48) .. (-1843.24,-56.20)
 .. controls (-1846.02,-55.91) and (-1842.47,-55.62) .. (-1848.33,-55.62)
 .. controls (-1854.18,-55.62) and (-1853.51,-54.95) .. (-1856.49,-55.62)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1856.49,-55.62)
 .. controls (-1856.49,-55.62) and (-1858.98,-55.72) .. (-1863.02,-56.10)
 .. controls (-1867.05,-56.49) and (-1868.97,-56.97) .. (-1874.73,-57.74)
 .. controls (-1880.49,-58.51) and (-1886.25,-58.89) .. (-1890.47,-59.18)
 .. controls (-1894.69,-59.46) and (-1892.20,-59.85) .. (-1897.67,-59.37)
 .. controls (-1903.14,-58.89) and (-1899.78,-58.02) .. (-1907.27,-58.89)
 .. controls (-1914.75,-59.75) and (-1918.78,-60.42) .. (-1922.43,-60.42)
 .. controls (-1926.08,-60.42) and (-1931.27,-60.52) .. (-1933.00,-60.61)
 .. controls (-1934.73,-60.71) and (-1935.21,-60.13) .. (-1938.76,-61.19)
 .. controls (-1942.31,-62.25) and (-1945.48,-63.30) .. (-1952.01,-64.17)
 .. controls (-1958.54,-65.03) and (-1957.49,-64.55) .. (-1961.42,-65.22)
 .. controls (-1965.36,-65.89) and (-1957.20,-64.74) .. (-1967.76,-66.37)
 .. controls (-1978.32,-68.00) and (-1974.29,-67.62) .. (-1981.10,-68.20)
 .. controls (-1987.92,-68.77) and (-1988.02,-68.87) .. (-1990.99,-68.77)
 .. controls (-1993.97,-68.68) and (-1995.60,-68.39) .. (-1998.10,-68.29)
 .. controls (-2000.59,-68.19) and (-1999.82,-69.44) .. (-2003.28,-68.87)
 .. controls (-2006.74,-68.29) and (-2007.13,-67.62) .. (-2010.68,-67.33)
 .. controls (-2014.23,-67.04) and (-2018.27,-67.13) .. (-2021.92,-66.46)
 .. controls (-2025.57,-65.79) and (-2021.34,-65.60) .. (-2028.35,-65.40)
 .. controls (-2035.36,-65.20) and (-2032.67,-65.11) .. (-2038.53,-64.72)
 .. controls (-2044.39,-64.33) and (-2045.63,-64.71) .. (-2050.25,-64.32)
 .. controls (-2054.86,-63.93) and (-2057.27,-62.87) .. (-2059.10,-63.16)
 .. controls (-2060.92,-63.45) and (-2067.17,-64.21) .. (-2073.04,-64.70)
 .. controls (-2078.90,-65.18) and (-2073.99,-65.47) .. (-2081.88,-65.29)
 .. controls (-2089.76,-65.11) and (-2088.71,-64.05) .. (-2095.81,-64.92)
 .. controls (-2102.90,-65.79) and (-2103.66,-66.27) .. (-2108.36,-65.99)
 .. controls (-2113.06,-65.70) and (-2110.28,-65.60) .. (-2116.52,-65.41)
 .. controls (-2122.76,-65.21) and (-2118.44,-65.79) .. (-2125.84,-64.93)
 .. controls (-2133.24,-64.06) and (-2133.05,-63.87) .. (-2138.81,-63.96)
 .. controls (-2144.58,-64.06) and (-2144.58,-63.77) .. (-2148.24,-63.10)
 .. controls (-2151.90,-62.43) and (-2153.93,-61.38) .. (-2156.24,-61.67)
 .. controls (-2158.54,-61.96) and (-2155.94,-62.15) .. (-2161.82,-61.96)
 .. controls (-2167.70,-61.77) and (-2169.02,-63.11) .. (-2173.19,-61.49)
 .. controls (-2177.37,-59.86) and (-2174.69,-58.99) .. (-2181.74,-58.71)
 .. controls (-2188.80,-58.42) and (-2186.47,-58.61) .. (-2191.23,-58.13)
 .. controls (-2196.00,-57.65) and (-2190.58,-57.17) .. (-2197.27,-57.56)
 .. controls (-2204.01,-57.94) and (-2199.92,-57.37) .. (-2205.77,-57.94)
 .. controls (-2211.66,-58.52) and (-2210.51,-57.95) .. (-2214.04,-58.43)
 .. controls (-2217.58,-58.91) and (-2213.47,-58.05) .. (-2219.01,-59.87)
 .. controls (-2224.56,-61.69) and (-2227.43,-63.32) .. (-2228.99,-63.90)
 .. controls (-2230.54,-64.47) and (-2231.53,-64.57) .. (-2235.63,-65.72)
 .. controls (-2239.71,-66.87) and (-2237.91,-66.97) .. (-2241.39,-67.07)
 .. controls (-2244.87,-67.17) and (-2246.16,-68.02) .. (-2250.25,-67.36)
 .. controls (-2254.40,-66.69) and (-2253.49,-67.26) .. (-2257.25,-66.13)
 .. controls (-2261.09,-64.97) and (-2261.09,-64.98) .. (-2263.02,-64.32)
 .. controls (-2264.98,-63.65) and (-2264.90,-64.31) .. (-2266.86,-62.61)
 .. controls (-2268.85,-60.89) and (-2271.09,-59.38) .. (-2272.50,-57.60)
 .. controls (-2273.93,-55.79) and (-2275.03,-56.28) .. (-2276.35,-49.89)
 .. controls (-2277.66,-43.54) and (-2278.90,-42.72) .. (-2279.84,-38.74)
 .. controls (-2280.77,-34.79) and (-2281.57,-33.87) .. (-2281.00,-28.83)
 .. controls (-2280.44,-23.80) and (-2280.84,-24.81) .. (-2279.64,-21.98)
 .. controls (-2278.44,-19.14) and (-2278.43,-20.49) .. (-2276.78,-14.94)
 .. controls (-2275.13,-9.39) and (-2274.76,-7.69) .. (-2274.38,-7.14)
 .. controls (-2274.00,-6.59) and (-2275.18,-8.68) .. (-2274.55,-3.65)
 .. controls (-2273.92,1.37) and (-2274.11,0.65) .. (-2273.74,3.86)
 .. controls (-2273.36,7.07) and (-2272.56,7.10) .. (-2274.50,10.63)
 .. controls (-2276.43,14.13) and (-2276.86,13.67) .. (-2277.54,16.00)
 .. controls (-2278.22,18.32) and (-2277.75,19.22) .. (-2277.70,21.40)
 .. controls (-2277.65,23.57) and (-2277.98,24.51) .. (-2278.15,25.28)
 .. controls (-2278.31,26.04) and (-2276.83,27.87) .. (-2278.41,30.36)
 .. controls (-2279.99,32.83) and (-2281.23,33.00) .. (-2282.01,35.68)
 .. controls (-2282.80,38.35) and (-2281.16,34.62) .. (-2283.57,39.66)
 .. controls (-2285.94,44.63) and (-2286.58,45.35) .. (-2286.95,45.99)
 .. controls (-2287.33,46.63) and (-2288.71,48.61) .. (-2289.06,49.93)
 .. controls (-2289.40,51.24) and (-2290.30,54.42) .. (-2291.93,56.60)
 .. controls (-2293.55,58.76) and (-2293.38,57.53) .. (-2294.54,60.24)
 .. controls (-2295.69,62.94) and (-2295.26,61.65) .. (-2296.86,65.04)
 .. controls (-2298.45,68.41) and (-2298.25,66.78) .. (-2299.38,69.86)
 .. controls (-2300.50,72.93) and (-2300.73,72.74) .. (-2300.57,74.82)
 .. controls (-2300.42,76.90) and (-2300.31,78.31) .. (-2300.31,78.31)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2409.78,50.14)
 .. controls (-2410.19,49.36) and (-2411.06,47.44) .. (-2411.87,45.25)
 .. controls (-2412.68,43.06) and (-2413.23,42.04) .. (-2413.92,40.04)
 .. controls (-2414.60,38.05) and (-2416.31,34.92) .. (-2417.08,33.21)
 .. controls (-2417.85,31.50) and (-2420.00,29.20) .. (-2421.58,26.43)
 .. controls (-2423.15,23.67) and (-2424.65,20.81) .. (-2427.06,17.63)
 .. controls (-2429.46,14.46) and (-2428.97,13.58) .. (-2432.25,10.32)
 .. controls (-2435.53,7.06) and (-2434.74,6.84) .. (-2439.03,3.61)
 .. controls (-2443.28,0.40) and (-2447.03,-1.47) .. (-2453.54,-5.84)
 .. controls (-2459.90,-10.11) and (-2461.81,-10.32) .. (-2467.12,-14.45)
 .. controls (-2472.23,-18.43) and (-2475.72,-21.70) .. (-2477.63,-23.49)
 .. controls (-2479.50,-25.23) and (-2479.03,-24.45) .. (-2483.52,-28.28)
 .. controls (-2487.88,-31.98) and (-2491.50,-35.92) .. (-2492.04,-36.89)
 .. controls (-2492.57,-37.86) and (-2495.35,-40.06) .. (-2497.50,-45.43)
 .. controls (-2499.64,-50.77) and (-2504.26,-62.08) .. (-2504.54,-65.01)
 .. controls (-2504.79,-67.77) and (-2504.82,-69.13) .. (-2504.78,-71.58)
 .. controls (-2504.74,-73.79) and (-2504.59,-72.66) .. (-2504.38,-76.40)
 .. controls (-2504.23,-79.01) and (-2503.90,-79.94) .. (-2503.57,-82.09)
 .. controls (-2503.17,-84.64) and (-2503.48,-84.03) .. (-2502.53,-86.33)
 .. controls (-2501.49,-88.86) and (-2499.93,-91.99) .. (-2499.03,-93.38)
 .. controls (-2498.10,-94.81) and (-2499.15,-93.59) .. (-2496.65,-96.69)
 .. controls (-2494.00,-99.96) and (-2489.06,-105.06) .. (-2485.98,-107.80)
 .. controls (-2482.75,-110.69) and (-2481.88,-111.63) .. (-2476.27,-115.39)
 .. controls (-2470.56,-119.22) and (-2467.08,-120.75) .. (-2464.31,-121.98)
 .. controls (-2461.58,-123.19) and (-2454.00,-126.14) .. (-2446.59,-126.92)
 .. controls (-2439.98,-127.62) and (-2438.40,-127.36) .. (-2434.78,-126.34)
 .. controls (-2431.96,-125.55) and (-2431.96,-125.76) .. (-2430.84,-124.24)
 .. controls (-2429.94,-123.01) and (-2429.63,-120.27) .. (-2430.89,-118.68)
 .. controls (-2432.42,-116.75) and (-2434.27,-115.93) .. (-2436.85,-114.32)
 .. controls (-2439.79,-112.49) and (-2444.54,-111.07) .. (-2446.06,-110.57)
 .. controls (-2447.61,-110.06) and (-2448.71,-109.97) .. (-2450.06,-109.61)
 .. controls (-2450.68,-109.44) and (-2455.83,-107.42) .. (-2456.91,-107.16)
 .. controls (-2457.90,-106.92) and (-2460.27,-106.39) .. (-2462.14,-106.23)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2462.51,-104.55)
 .. controls (-2462.51,-104.55) and (-2463.25,-104.71) .. (-2458.46,-104.63)
 .. controls (-2452.69,-104.54) and (-2452.94,-104.36) .. (-2448.45,-104.47)
 .. controls (-2444.05,-104.57) and (-2444.12,-104.49) .. (-2437.56,-104.48)
 .. controls (-2431.31,-104.46) and (-2429.08,-104.29) .. (-2426.23,-103.92)
 .. controls (-2423.49,-103.58) and (-2422.79,-103.69) .. (-2419.65,-103.01)
 .. controls (-2416.73,-102.39) and (-2419.12,-102.66) .. (-2414.36,-101.38)
 .. controls (-2410.45,-100.33) and (-2407.87,-98.05) .. (-2407.63,-97.98)
 .. controls (-2407.41,-97.91) and (-2408.35,-97.97) .. (-2407.21,-97.90)
 .. controls (-2406.77,-97.87) and (-2408.30,-95.75) .. (-2409.36,-95.52)
 .. controls (-2410.68,-95.22) and (-2409.54,-94.74) .. (-2414.72,-93.81)
 .. controls (-2422.14,-92.48) and (-2430.60,-92.01) .. (-2432.63,-92.32)
 .. controls (-2434.67,-92.64) and (-2439.56,-92.33) .. (-2442.70,-91.78)
 .. controls (-2445.84,-91.23) and (-2450.59,-89.89) .. (-2452.44,-90.22)
 .. controls (-2454.29,-90.54) and (-2453.89,-90.10) .. (-2459.91,-90.85)
 .. controls (-2465.94,-91.60) and (-2463.14,-90.88) .. (-2471.69,-91.45)
 .. controls (-2481.30,-92.09) and (-2483.49,-95.06) .. (-2480.79,-96.00)
 .. controls (-2475.97,-97.68) and (-2477.16,-95.56) .. (-2470.89,-95.75)
 .. controls (-2464.77,-95.94) and (-2463.28,-95.73) .. (-2482.79,-93.96)
 .. controls (-2490.14,-93.30) and (-2488.62,-93.44) .. (-2491.17,-93.29)
 .. controls (-2492.03,-93.25) and (-2485.78,-93.35) .. (-2488.33,-93.58)
 .. controls (-2492.18,-93.94) and (-2484.60,-93.77) .. (-2492.10,-93.37)
 .. controls (-2495.05,-93.21) and (-2489.79,-92.92) .. (-2485.50,-93.95)
 .. controls (-2484.83,-94.12) and (-2489.44,-90.13) .. (-2498.84,-95.71)
 .. controls (-2505.49,-99.65) and (-2483.73,-97.92) .. (-2492.80,-97.38)
 .. controls (-2511.11,-96.27) and (-2496.52,-96.57) .. (-2503.01,-96.71)
 .. controls (-2527.39,-97.24) and (-2533.68,-96.77) .. (-2532.23,-96.90)
 .. controls (-2526.75,-97.42) and (-2525.43,-97.69) .. (-2521.64,-97.48)
 .. controls (-2518.44,-97.30) and (-2515.85,-97.29) .. (-2512.70,-97.28)
 .. controls (-2510.43,-97.28) and (-2500.08,-99.91) .. (-2498.97,-98.63)
 .. controls (-2498.36,-97.92) and (-2507.32,-97.09) .. (-2499.23,-97.95)
 .. controls (-2491.20,-98.81) and (-2487.24,-99.00) .. (-2483.79,-99.01)
 .. controls (-2416.97,-99.19) and (-2333.69,-96.93) .. (-2326.71,-96.42)
 .. controls (-2323.13,-96.16) and (-2323.34,-96.23) .. (-2319.03,-96.81)
 .. controls (-2314.71,-97.38) and (-2313.35,-97.09) .. (-2309.12,-97.00)
 .. controls (-2304.90,-96.90) and (-2300.77,-96.71) .. (-2297.31,-97.00)
 .. controls (-2293.86,-97.28) and (-2292.70,-96.71) .. (-2290.01,-97.00)
 .. controls (-2287.33,-97.28) and (-2285.50,-96.42) .. (-2284.73,-96.71)
 .. controls (-2283.97,-97.00) and (-2278.30,-97.19) .. (-2277.92,-97.38)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2277.92,-97.38)
 .. controls (-2277.34,-97.57) and (-2275.52,-99.20) .. (-2273.31,-99.78)
 .. controls (-2271.11,-100.36) and (-2267.94,-100.65) .. (-2265.63,-100.65)
 .. controls (-2263.33,-100.65) and (-2262.08,-100.55) .. (-2259.01,-100.26)
 .. controls (-2255.93,-99.98) and (-2258.53,-99.69) .. (-2252.96,-100.17)
 .. controls (-2247.39,-100.65) and (-2252.19,-100.07) .. (-2244.99,-100.64)
 .. controls (-2237.79,-101.22) and (-2236.54,-101.41) .. (-2230.40,-102.08)
 .. controls (-2224.25,-102.75) and (-2220.99,-102.75) .. (-2220.99,-102.75)
 .. controls (-2220.99,-102.75) and (-2218.88,-102.74) .. (-2213.98,-102.17)
 .. controls (-2209.08,-101.59) and (-2208.60,-100.73) .. (-2204.96,-100.92)
 .. controls (-2201.31,-101.11) and (-2204.09,-101.30) .. (-2199.87,-101.11)
 .. controls (-2195.65,-100.92) and (-2196.61,-101.11) .. (-2192.00,-100.35)
 .. controls (-2187.39,-99.59) and (-2187.77,-99.20) .. (-2182.69,-98.92)
 .. controls (-2177.60,-98.63) and (-2176.44,-99.01) .. (-2172.80,-99.40)
 .. controls (-2169.15,-99.78) and (-2171.07,-99.78) .. (-2167.71,-99.78)
 .. controls (-2164.35,-99.78) and (-2161.18,-100.74) .. (-2160.02,-100.45)
 .. controls (-2158.87,-100.16) and (-2155.13,-100.64) .. (-2151.96,-100.54)
 .. controls (-2148.79,-100.44) and (-2150.81,-100.44) .. (-2148.03,-100.44)
 .. controls (-2145.24,-100.44) and (-2150.43,-100.82) .. (-2142.94,-100.35)
 .. controls (-2135.45,-99.87) and (-2136.22,-100.25) .. (-2132.48,-99.96)
 .. controls (-2128.73,-99.68) and (-2130.84,-99.48) .. (-2125.85,-99.68)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2125.85,-99.68)
 .. controls (-2123.45,-99.39) and (-2120.09,-100.45) .. (-2114.81,-100.26)
 .. controls (-2109.53,-100.07) and (-2113.09,-99.78) .. (-2108.38,-99.97)
 .. controls (-2103.68,-100.17) and (-2106.94,-100.17) .. (-2100.99,-100.45)
 .. controls (-2095.04,-100.74) and (-2095.52,-101.41) .. (-2090.81,-100.84)
 .. controls (-2086.11,-100.26) and (-2089.66,-99.78) .. (-2083.71,-100.45)
 .. controls (-2077.76,-101.12) and (-2076.32,-102.38) .. (-2070.36,-101.41)
 .. controls (-2064.41,-100.45) and (-2066.33,-99.38) .. (-2060.29,-99.96)
 .. controls (-2054.24,-100.54) and (-2054.91,-100.73) .. (-2049.92,-100.93)
 .. controls (-2044.93,-101.12) and (-2042.91,-101.31) .. (-2041.47,-100.64)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-2041.47,-100.64)
 .. controls (-2041.47,-100.64) and (-2040.32,-100.35) .. (-2038.11,-100.16)
 .. controls (-2035.90,-99.97) and (-2035.52,-99.59) .. (-2031.58,-99.68)
 .. controls (-2027.65,-99.78) and (-2027.45,-100.45) .. (-2023.23,-100.16)
 .. controls (-2019.01,-99.88) and (-2018.33,-100.26) .. (-2012.57,-100.16)
 .. controls (-2006.81,-100.07) and (-2007.01,-99.97) .. (-2003.84,-99.97)
 .. controls (-2000.67,-99.97) and (-2000.96,-99.30) .. (-1997.12,-99.49)
 .. controls (-1993.28,-99.68) and (-1993.28,-99.40) .. (-1988.57,-100.26)
 .. controls (-1983.87,-101.12) and (-1983.10,-102.37) .. (-1980.22,-101.51)
 .. controls (-1977.34,-100.65) and (-1975.23,-99.40) .. (-1971.87,-98.73)
 .. controls (-1968.51,-98.05) and (-1969.57,-97.96) .. (-1965.44,-97.67)
 .. controls (-1961.31,-97.38) and (-1963.52,-97.67) .. (-1958.43,-97.19)
 .. controls (-1953.34,-96.71) and (-1954.30,-97.09) .. (-1949.50,-96.23)
 .. controls (-1944.70,-95.37) and (-1948.25,-96.52) .. (-1942.21,-94.60)
 .. controls (-1936.16,-92.68) and (-1940.48,-93.54) .. (-1933.85,-91.91)
 .. controls (-1927.23,-90.28) and (-1933.18,-90.86) .. (-1924.64,-90.18)
 .. controls (-1916.09,-89.51) and (-1919.07,-89.32) .. (-1914.85,-89.32)
 .. controls (-1910.62,-89.32) and (-1911.87,-89.13) .. (-1907.84,-89.61)
 .. controls (-1903.81,-90.09) and (-1908.03,-89.03) .. (-1900.45,-88.46)
 .. controls (-1892.86,-87.88) and (-1892.96,-87.88) .. (-1888.35,-88.55)
 .. controls (-1883.74,-89.23) and (-1885.76,-89.13) .. (-1880.29,-89.23)
 .. controls (-1874.81,-89.32) and (-1877.50,-89.32) .. (-1872.51,-89.32)
 .. controls (-1867.52,-89.32) and (-1868.86,-89.90) .. (-1864.54,-88.74)
 .. controls (-1860.22,-87.59) and (-1863.20,-87.11) .. (-1857.44,-87.11)
 .. controls (-1851.68,-87.11) and (-1853.60,-87.30) .. (-1849.09,-87.11)
 .. controls (-1844.57,-86.92) and (-1848.22,-86.24) .. (-1842.75,-86.72)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1840.16,-87.11)
 .. controls (-1834.01,-87.30) and (-1835.45,-87.30) .. (-1830.56,-87.20)
 .. controls (-1825.66,-87.11) and (-1833.15,-87.68) .. (-1823.45,-87.30)
 .. controls (-1813.76,-86.92) and (-1811.26,-87.59) .. (-1808.09,-86.34)
 .. controls (-1804.93,-85.09) and (-1806.65,-85.77) .. (-1801.85,-84.90)
 .. controls (-1797.05,-84.04) and (-1797.73,-84.23) .. (-1793.21,-83.85)
 .. controls (-1788.70,-83.46) and (-1784.19,-85.86) .. (-1779.01,-85.19)
 .. controls (-1773.82,-84.51) and (-1773.15,-84.13) .. (-1766.91,-84.22)
 .. controls (-1760.67,-84.32) and (-1761.24,-84.99) .. (-1754.04,-84.22)
 .. controls (-1746.84,-83.45) and (-1752.99,-84.70) .. (-1744.35,-83.45)
 .. controls (-1735.71,-82.20) and (-1736.96,-81.82) .. (-1734.17,-82.11)
 .. controls (-1731.39,-82.39) and (-1729.76,-83.35) .. (-1724.57,-83.74)
 .. controls (-1719.39,-84.12) and (-1715.45,-84.60) .. (-1712.29,-84.60)
 .. controls (-1709.12,-84.61) and (-1704.80,-85.47) .. (-1704.80,-85.47)
 .. controls (-1704.80,-85.47) and (-1704.99,-86.91) .. (-1697.98,-87.30)
 .. controls (-1690.97,-87.68) and (-1686.94,-89.31) .. (-1680.99,-89.22)
 .. controls (-1675.04,-89.12) and (-1677.73,-88.45) .. (-1669.95,-87.78)
 .. controls (-1662.17,-87.11) and (-1663.71,-87.01) .. (-1658.05,-86.63)
 .. controls (-1652.38,-86.25) and (-1651.90,-86.25) .. (-1647.29,-86.63)
 .. controls (-1642.69,-87.01) and (-1643.55,-87.40) .. (-1638.85,-87.21)
 .. controls (-1634.14,-87.02) and (-1625.98,-87.69) .. (-1624.93,-87.30)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1624.93,-87.30)
 .. controls (-1624.93,-87.30) and (-1623.39,-86.73) .. (-1618.30,-86.73)
 .. controls (-1613.21,-86.73) and (-1615.71,-87.02) .. (-1609.28,-86.25)
 .. controls (-1602.85,-85.48) and (-1604.86,-84.71) .. (-1597.95,-85.29)
 .. controls (-1591.04,-85.86) and (-1590.17,-85.48) .. (-1585.28,-85.96)
 .. controls (-1580.38,-86.44) and (-1580.29,-86.82) .. (-1575.29,-87.02)
 .. controls (-1570.30,-87.21) and (-1560.03,-87.59) .. (-1558.40,-87.78)
 .. controls (-1556.77,-87.98) and (-1559.84,-88.65) .. (-1555.52,-88.94)
 .. controls (-1551.20,-89.22) and (-1546.11,-90.95) .. (-1541.21,-91.63)
 .. controls (-1536.32,-92.30) and (-1537.18,-92.01) .. (-1531.52,-92.97)
 .. controls (-1525.86,-93.93) and (-1527.97,-93.64) .. (-1523.07,-94.22)
 .. controls (-1518.18,-94.80) and (-1517.70,-94.89) .. (-1514.34,-95.18)
 .. controls (-1510.98,-95.47) and (-1512.32,-95.76) .. (-1507.81,-95.66)
 .. controls (-1503.29,-95.57) and (-1505.60,-95.76) .. (-1500.22,-95.28)
 .. controls (-1494.85,-94.80) and (-1497.82,-96.34) .. (-1492.64,-94.32)
 .. controls (-1487.45,-92.31) and (-1487.65,-91.44) .. (-1485.05,-90.87)
 .. controls (-1482.46,-90.29) and (-1477.47,-89.62) .. (-1477.47,-89.62)
 .. controls (-1477.47,-89.62) and (-1479.39,-90.10) .. (-1471.61,-89.72)
 .. controls (-1463.84,-89.33) and (-1463.26,-89.14) .. (-1460.19,-88.85)
 .. controls (-1457.12,-88.56) and (-1458.84,-88.47) .. (-1454.14,-88.28)
 .. controls (-1449.44,-88.08) and (-1449.82,-87.70) .. (-1444.35,-87.51)
 .. controls (-1438.88,-87.31) and (-1443.96,-87.89) .. (-1437.24,-87.31)
 .. controls (-1430.52,-86.74) and (-1429.76,-87.12) .. (-1423.90,-87.02)
 .. controls (-1418.04,-86.93) and (-1418.43,-87.02) .. (-1409.88,-87.79)
 .. controls (-1401.34,-88.55) and (-1403.17,-88.94) .. (-1396.83,-89.03)
 .. controls (-1390.49,-89.13) and (-1392.99,-88.94) .. (-1387.42,-88.75)
 .. controls (-1381.85,-88.56) and (-1384.16,-88.36) .. (-1378.69,-88.17)
 .. controls (-1373.21,-87.98) and (-1370.53,-87.60) .. (-1366.59,-87.89)
 .. controls (-1362.65,-88.17) and (-1359.58,-88.65) .. (-1357.28,-88.08)
 .. controls (-1354.97,-87.50) and (-1358.43,-88.27) .. (-1353.73,-87.21)
 .. controls (-1349.02,-86.16) and (-1344.70,-86.74) .. (-1344.22,-86.64)
 .. controls (-1343.74,-86.55) and (-1337.50,-86.07) .. (-1334.33,-86.26)
 .. controls (-1331.17,-86.45) and (-1332.13,-86.93) .. (-1328.57,-86.74)
 .. controls (-1325.02,-86.55) and (-1327.13,-86.07) .. (-1322.24,-86.74)
 .. controls (-1317.34,-87.42) and (-1317.82,-87.32) .. (-1314.17,-87.61)
 .. controls (-1310.53,-87.89) and (-1313.89,-88.66) .. (-1307.93,-87.89)
 .. controls (-1301.98,-87.12) and (-1304.38,-87.03) .. (-1299.87,-87.22)
 .. controls (-1295.36,-87.41) and (-1296.03,-87.41) .. (-1292.00,-87.22)
 .. controls (-1287.97,-87.03) and (-1287.01,-86.64) .. (-1282.59,-86.74)
 .. controls (-1278.17,-86.83) and (-1275.77,-86.74) .. (-1274.33,-86.64)
 .. controls (-1272.89,-86.54) and (-1271.45,-86.16) .. (-1266.85,-86.45)
 .. controls (-1262.24,-86.74) and (-1258.11,-87.60) .. (-1254.56,-87.12)
 .. controls (-1251.01,-86.64) and (-1254.08,-86.93) .. (-1248.99,-86.26)
 .. controls (-1243.90,-85.59) and (-1245.44,-85.68) .. (-1242.17,-85.49)
 .. controls (-1238.91,-85.30) and (-1241.12,-85.68) .. (-1236.13,-85.11)
 .. controls (-1231.13,-84.53) and (-1232.67,-84.24) .. (-1228.83,-84.44)
 .. controls (-1224.99,-84.63) and (-1226.43,-84.82) .. (-1222.11,-84.92)
 .. controls (-1217.79,-85.01) and (-1218.37,-85.49) .. (-1215.29,-84.82)
 .. controls (-1212.22,-84.15) and (-1210.97,-86.35) .. (-1203.29,-85.78)
 .. controls (-1195.61,-85.20) and (-1195.90,-85.01) .. (-1192.83,-84.91)
 .. controls (-1189.76,-84.82) and (-1190.62,-84.91) .. (-1186.97,-84.53)
 .. controls (-1183.33,-84.15) and (-1185.82,-84.43) .. (-1181.79,-84.05)
 .. controls (-1177.76,-83.66) and (-1177.66,-83.38) .. (-1174.30,-83.47)
 .. controls (-1170.94,-83.57) and (-1165.85,-84.04) .. (-1163.26,-84.33)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-1163.26,-84.33)
 .. controls (-1163.26,-84.33) and (-1157.79,-85.29) .. (-1154.62,-85.10)
 .. controls (-1151.45,-84.91) and (-1151.26,-84.14) .. (-1146.17,-84.43)
 .. controls (-1141.09,-84.72) and (-1135.71,-84.33) .. (-1131.10,-84.24)
 .. controls (-1126.49,-84.14) and (-1127.55,-83.47) .. (-1122.27,-83.76)
 .. controls (-1116.99,-84.04) and (-1117.57,-84.81) .. (-1111.33,-84.43)
 .. controls (-1105.09,-84.04) and (-1103.93,-83.85) .. (-1098.85,-84.33)
 .. controls (-1093.76,-84.81) and (-1092.22,-83.95) .. (-1088.48,-83.66)
 .. controls (-1084.73,-83.37) and (-1087.90,-83.18) .. (-1082.53,-83.28)
 .. controls (-1077.15,-83.37) and (-1072.06,-83.85) .. (-1067.55,-83.66)
 .. controls (-1063.04,-83.47) and (-1069.47,-82.89) .. (-1060.83,-83.38)
 .. controls (-1052.19,-83.86) and (-1052.96,-84.53) .. (-1046.33,-84.24)
 .. controls (-1039.71,-83.95) and (-1034.14,-83.67) .. (-1031.93,-83.48)
 .. controls (-1029.73,-83.28) and (-1030.40,-82.80) .. (-1027.23,-83.19)
 .. controls (-1024.06,-83.57) and (-1021.57,-81.36) .. (-1018.78,-81.08)
 .. controls (-1016.00,-80.79) and (-1015.90,-80.40) .. (-1011.20,-80.12)
 .. controls (-1006.49,-79.83) and (-1009.28,-80.31) .. (-1004.57,-79.92)
 .. controls (-999.87,-79.54) and (-996.80,-78.77) .. (-992.76,-78.00)
 .. controls (-988.73,-77.24) and (-992.38,-77.81) .. (-988.16,-77.24)
 .. controls (-983.93,-76.66) and (-988.83,-77.24) .. (-981.63,-76.56)
 .. controls (-974.43,-75.89) and (-977.98,-76.18) .. (-972.80,-75.70)
 .. controls (-967.61,-75.22) and (-967.13,-74.64) .. (-963.48,-74.55)
 .. controls (-959.84,-74.45) and (-958.11,-75.22) .. (-953.31,-74.45)
 .. controls (-948.51,-73.68) and (-947.93,-73.49) .. (-943.04,-73.39)
 .. controls (-938.14,-73.30) and (-938.81,-73.68) .. (-935.07,-73.30)
 .. controls (-931.32,-72.91) and (-934.11,-73.39) .. (-929.69,-72.72)
 .. controls (-925.28,-72.05) and (-926.62,-72.15) .. (-921.05,-72.24)
 .. controls (-915.48,-72.34) and (-918.17,-72.15) .. (-913.95,-72.34)
 .. controls (-909.72,-72.53) and (-908.57,-72.63) .. (-905.31,-73.39)
 .. controls (-902.04,-74.16) and (-901.56,-74.45) .. (-897.24,-75.51)
 .. controls (-892.92,-76.56) and (-891.96,-76.95) .. (-888.51,-77.91)
 .. controls (-885.05,-78.87) and (-888.09,-78.13) .. (-884.28,-79.06)
 .. controls (-875.64,-81.17) and (-879.96,-82.99) .. (-873.53,-82.71)
 .. controls (-867.10,-82.42) and (-868.93,-82.52) .. (-864.61,-82.23)
 .. controls (-860.29,-81.94) and (-858.85,-82.90) .. (-853.18,-82.23)
 .. controls (-847.52,-81.56) and (-850.30,-81.08) .. (-842.14,-81.56)
 .. controls (-833.98,-82.04) and (-833.98,-82.14) .. (-830.43,-81.95)
 .. controls (-826.88,-81.75) and (-829.76,-81.75) .. (-824.29,-81.56)
 .. controls (-818.81,-81.37) and (-818.24,-81.27) .. (-815.74,-80.89)
 .. controls (-813.24,-80.51) and (-803.07,-81.27) .. (-802.30,-81.18)
 .. controls (-801.53,-81.08) and (-800.67,-81.56) .. (-794.14,-81.27)
 .. controls (-787.61,-80.98) and (-791.64,-81.37) .. (-787.04,-80.89)
 .. controls (-782.43,-80.41) and (-787.13,-80.60) .. (-780.70,-80.21)
 .. controls (-774.27,-79.83) and (-776.00,-79.75) .. (-772.35,-80.02)
 .. controls (-763.32,-80.69) and (-763.23,-80.88) .. (-760.16,-81.08)
 .. controls (-757.09,-81.27) and (-757.37,-81.17) .. (-753.73,-80.98)
 .. controls (-750.08,-80.79) and (-745.08,-79.93) .. (-742.01,-79.26)
 .. controls (-738.94,-78.59) and (-740.19,-79.74) .. (-732.80,-79.07)
 .. controls (-725.40,-78.40) and (-723.29,-78.49) .. (-718.88,-78.69)
 .. controls (-714.46,-78.88) and (-716.00,-79.26) .. (-711.20,-79.36)
 .. controls (-706.40,-79.46) and (-710.04,-79.36) .. (-703.80,-79.84)
 .. controls (-697.56,-80.32) and (-699.39,-80.80) .. (-694.78,-80.61)
 .. controls (-690.17,-80.42) and (-690.94,-80.90) .. (-686.52,-79.84)
 .. controls (-682.11,-78.78) and (-681.72,-78.30) .. (-677.60,-78.49)
 .. controls (-673.47,-78.68) and (-676.54,-78.68) .. (-669.63,-78.88)
 .. controls (-662.72,-79.08) and (-660.99,-79.27) .. (-658.88,-79.08)
 .. controls (-656.76,-78.88) and (-651.48,-79.36) .. (-645.72,-78.88)
 .. controls (-639.96,-78.40) and (-640.35,-77.63) .. (-636.60,-78.30)
 .. controls (-632.86,-78.97) and (-635.64,-79.07) .. (-629.11,-79.07)
 .. controls (-622.59,-79.07) and (-624.79,-79.16) .. (-620.95,-79.07)
 .. controls (-617.11,-78.97) and (-616.92,-79.16) .. (-613.56,-78.97)
 .. controls (-610.20,-78.77) and (-609.34,-79.83) .. (-606.46,-79.64)
 .. controls (-603.58,-79.45) and (-606.36,-79.45) .. (-600.41,-78.68)
 .. controls (-594.46,-77.91) and (-598.30,-77.72) .. (-590.81,-78.20)
 .. controls (-583.32,-78.68) and (-581.98,-79.07) .. (-577.85,-79.16)
 .. controls (-573.72,-79.26) and (-575.74,-79.64) .. (-572.57,-79.16)
 .. controls (-569.40,-78.69) and (-570.56,-80.32) .. (-565.66,-79.65)
 .. controls (-560.76,-78.98) and (-559.90,-77.92) .. (-555.10,-78.50)
 .. controls (-550.30,-79.07) and (-552.99,-79.27) .. (-547.80,-79.07)
 .. controls (-542.62,-78.88) and (-541.18,-78.79) .. (-538.59,-78.21)
 .. controls (-536.00,-77.63) and (-538.49,-77.44) .. (-532.83,-77.63)
 .. controls (-527.16,-77.83) and (-529.95,-78.21) .. (-524.76,-77.83)
 .. controls (-519.58,-77.44) and (-521.21,-77.06) .. (-516.99,-77.25)
 .. controls (-512.76,-77.44) and (-507.10,-78.59) .. (-504.89,-78.11)
 .. controls (-502.68,-77.63) and (-497.69,-78.31) .. (-493.08,-78.50)
 .. controls (-488.47,-78.69) and (-486.55,-79.17) .. (-483.67,-79.17)
 .. controls (-480.79,-79.17) and (-482.71,-78.88) .. (-475.51,-78.78)
 .. controls (-468.31,-78.69) and (-465.63,-79.17) .. (-462.84,-78.88)
 .. controls (-460.06,-78.59) and (-464.57,-78.78) .. (-458.33,-78.59)
 .. controls (-452.09,-78.40) and (-454.01,-78.69) .. (-449.12,-78.30)
 .. controls (-444.22,-77.92) and (-447.10,-79.27) .. (-442.01,-78.31)
 .. controls (-436.92,-77.35) and (-437.60,-77.16) .. (-434.24,-76.77)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-434.24,-76.77)
 .. controls (-434.24,-76.77) and (-435.29,-76.68) .. (-431.93,-76.10)
 .. controls (-428.57,-75.53) and (-424.25,-75.33) .. (-420.51,-74.76)
 .. controls (-416.76,-74.18) and (-410.91,-74.56) .. (-407.16,-74.66)
 .. controls (-403.42,-74.75) and (-403.99,-74.75) .. (-400.15,-74.56)
 .. controls (-396.31,-74.37) and (-397.95,-73.89) .. (-392.67,-74.65)
 .. controls (-387.39,-75.42) and (-391.03,-75.90) .. (-382.97,-75.99)
 .. controls (-374.91,-76.09) and (-374.71,-76.28) .. (-372.03,-76.47)
 .. controls (-369.34,-76.66) and (-369.82,-76.76) .. (-363.87,-77.05)
 .. controls (-357.92,-77.34) and (-362.04,-77.05) .. (-354.27,-77.34)
 .. controls (-346.49,-77.63) and (-348.32,-77.63) .. (-343.52,-77.34)
 .. controls (-338.72,-77.06) and (-341.12,-77.73) .. (-336.32,-76.86)
 .. controls (-331.52,-76.00) and (-331.32,-76.39) .. (-327.29,-75.81)
 .. controls (-323.26,-75.24) and (-323.55,-75.72) .. (-320.57,-75.24)
 .. controls (-317.60,-74.76) and (-320.28,-75.14) .. (-314.62,-74.37)
 .. controls (-308.96,-73.60) and (-309.63,-74.08) .. (-304.83,-73.22)
 .. controls (-300.03,-72.35) and (-304.35,-71.68) .. (-297.82,-72.06)
 .. controls (-291.29,-72.45) and (-283.23,-73.12) .. (-281.88,-73.40)
 .. controls (-280.54,-73.69) and (-282.65,-75.71) .. (-277.18,-74.94)
 .. controls (-271.71,-74.17) and (-275.64,-74.65) .. (-268.15,-73.98)
 .. controls (-260.67,-73.31) and (-263.55,-73.41) .. (-258.46,-72.93)
 .. controls (-253.37,-72.45) and (-254.23,-72.84) .. (-249.53,-72.26)
 .. controls (-244.83,-71.69) and (-245.50,-71.69) .. (-240.70,-71.49)
 .. controls (-235.90,-71.30) and (-236.47,-70.82) .. (-232.15,-71.01)
 .. controls (-227.83,-71.21) and (-229.47,-71.40) .. (-223.71,-71.59)
 .. controls (-217.95,-71.78) and (-218.91,-72.17) .. (-215.64,-71.97)
 .. controls (-212.38,-71.78) and (-210.27,-71.30) .. (-208.54,-71.78)
 .. controls (-206.81,-72.26) and (-203.16,-71.40) .. (-202.11,-71.40)
 .. controls (-201.05,-71.40) and (-198.75,-70.72) .. (-195.96,-70.82)
 .. controls (-193.18,-70.92) and (-194.62,-71.40) .. (-190.97,-71.20)
 .. controls (-187.32,-71.01) and (-189.05,-71.68) .. (-184.35,-70.92)
 .. controls (-179.64,-70.15) and (-180.22,-69.96) .. (-176.67,-69.96)
 .. controls (-173.11,-69.96) and (-176.76,-70.24) .. (-171.39,-69.96)
 .. controls (-166.01,-69.67) and (-165.82,-69.96) .. (-162.46,-69.38)
 .. controls (-159.10,-68.80) and (-160.35,-68.80) .. (-156.89,-68.90)
 .. controls (-153.43,-68.99) and (-155.26,-68.71) .. (-148.92,-68.99)
 .. controls (-142.59,-69.28) and (-141.05,-69.09) .. (-137.79,-69.18)
 .. controls (-134.52,-69.28) and (-135.00,-68.99) .. (-131.35,-69.37)
 .. controls (-127.71,-69.76) and (-127.42,-69.08) .. (-122.43,-68.70)
 .. controls (-117.44,-68.32) and (-120.22,-68.32) .. (-114.36,-68.13)
 .. controls (-108.51,-67.94) and (-111.68,-68.61) .. (-106.11,-67.94)
 .. controls (-100.54,-67.27) and (-101.50,-66.88) .. (-98.14,-67.07)
 .. controls (-94.78,-67.27) and (-98.04,-67.17) .. (-92.28,-67.46)
 .. controls (-86.52,-67.75) and (-88.64,-67.07) .. (-83.36,-67.65)
 .. controls (-78.08,-68.22) and (-81.44,-67.46) .. (-76.54,-67.94)
 .. controls (-71.64,-68.42) and (-73.18,-68.32) .. (-68.48,-68.42)
 .. controls (-63.77,-68.51) and (-66.27,-67.65) .. (-61.85,-68.51)
 .. controls (-57.44,-69.37) and (-55.04,-68.03) .. (-53.31,-68.03)
 .. controls (-51.58,-68.03) and (-50.14,-67.36) .. (-46.01,-67.65)
 .. controls (-41.88,-67.93) and (-44.96,-68.13) .. (-40.06,-68.32)
 .. controls (-35.16,-68.51) and (-35.93,-68.32) .. (-31.80,-68.03)
 .. controls (-27.68,-67.74) and (-31.32,-67.64) .. (-26.24,-67.93)
 .. controls (-21.15,-68.22) and (-21.82,-68.22) .. (-19.42,-68.32)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-19.42,-68.32)
 .. controls (-19.42,-68.32) and (-15.87,-68.70) .. (-14.43,-68.60)
 .. controls (-12.99,-68.51) and (-11.16,-68.22) .. (-6.94,-67.93)
 .. controls (-2.72,-67.64) and (-5.21,-67.26) .. (0.93,-67.64)
 .. controls (7.08,-68.03) and (7.36,-67.74) .. (11.30,-67.93)
 .. controls (15.24,-68.12) and (14.47,-67.36) .. (18.50,-67.64)
 .. controls (22.53,-67.93) and (20.13,-68.32) .. (25.70,-68.12)
 .. controls (31.27,-67.93) and (35.30,-68.13) .. (38.56,-67.84)
 .. controls (41.83,-67.55) and (41.44,-68.22) .. (46.72,-68.13)
 .. controls (52.00,-68.03) and (52.77,-67.94) .. (56.52,-67.55)
 .. controls (60.26,-67.17) and (59.59,-66.98) .. (63.52,-66.98)
 .. controls (67.46,-66.98) and (65.54,-67.65) .. (70.53,-67.55)
 .. controls (75.52,-67.46) and (76.68,-67.55) .. (78.98,-67.46)
 .. controls (81.28,-67.36) and (79.56,-67.55) .. (84.36,-66.88)
 .. controls (89.16,-66.21) and (85.51,-66.31) .. (91.56,-66.21)
 .. controls (97.60,-66.11) and (96.16,-67.27) .. (100.29,-66.59)
 .. controls (104.42,-65.92) and (103.17,-65.83) .. (109.99,-65.35)
 .. controls (116.81,-64.87) and (113.16,-64.39) .. (119.21,-64.48)
 .. controls (125.25,-64.57) and (123.72,-64.57) .. (128.52,-64.66)
 .. controls (133.32,-64.75) and (132.16,-65.14) .. (136.58,-64.66)
 .. controls (140.99,-64.18) and (144.74,-64.28) .. (147.71,-63.90)
 .. controls (150.69,-63.51) and (150.40,-63.80) .. (153.95,-63.32)
 .. controls (157.51,-62.84) and (157.60,-62.46) .. (161.25,-62.27)
 .. controls (164.90,-62.08) and (171.14,-61.12) .. (172.58,-61.02)
 .. controls (174.02,-60.93) and (173.63,-62.46) .. (178.24,-61.98)
 .. controls (182.85,-61.50) and (179.97,-61.12) .. (187.75,-60.93)
 .. controls (195.52,-60.74) and (194.27,-60.83) .. (198.59,-60.45)
 .. controls (202.91,-60.06) and (202.82,-60.83) .. (207.91,-61.02)
 .. controls (213.00,-61.22) and (209.25,-60.45) .. (215.01,-61.12)
 .. controls (220.77,-61.79) and (222.21,-61.98) .. (224.80,-61.88)
 .. controls (227.40,-61.79) and (225.67,-61.31) .. (231.14,-61.69)
 .. controls (236.61,-62.07) and (237.28,-62.26) .. (241.99,-62.17)
 .. controls (246.69,-62.07) and (249.38,-61.97) .. (256.10,-61.11)
 .. controls (262.82,-60.25) and (265.12,-59.19) .. (269.44,-58.52)
 .. controls (273.76,-57.85) and (272.23,-58.04) .. (276.93,-57.66)
 .. controls (281.63,-57.27) and (279.43,-56.99) .. (284.80,-57.37)
 .. controls (290.18,-57.75) and (290.75,-58.14) .. (295.84,-58.14)
 .. controls (300.93,-58.14) and (300.45,-58.04) .. (304.67,-57.94)
 .. controls (308.90,-57.85) and (311.39,-57.46) .. (315.52,-57.75)
 .. controls (319.65,-58.04) and (320.03,-58.71) .. (325.70,-58.61)
 .. controls (331.36,-58.52) and (334.82,-58.42) .. (338.27,-58.52)
 .. controls (341.73,-58.61) and (340.19,-58.90) .. (344.51,-58.23)
 .. controls (348.83,-57.56) and (346.82,-57.65) .. (351.14,-57.36)
 .. controls (355.46,-57.08) and (354.79,-57.17) .. (361.12,-56.12)
 .. controls (367.46,-55.06) and (367.46,-55.64) .. (372.45,-54.39)
 .. controls (377.44,-53.14) and (377.73,-53.24) .. (382.24,-52.66)
 .. controls (386.75,-52.08) and (384.45,-52.47) .. (389.35,-51.60)
 .. controls (394.24,-50.74) and (391.55,-50.36) .. (396.74,-50.55)
 .. controls (401.92,-50.74) and (400.96,-51.41) .. (406.24,-51.12)
 .. controls (411.52,-50.84) and (416.42,-51.03) .. (419.68,-50.93)
 .. controls (422.95,-50.84) and (418.34,-51.03) .. (426.11,-50.93)
 .. controls (433.89,-50.84) and (430.15,-50.84) .. (435.81,-50.84)
 .. controls (441.48,-50.84) and (441.48,-50.84) .. (446.47,-50.64)
 .. controls (451.46,-50.45) and (451.46,-50.35) .. (455.39,-50.06)
 .. controls (459.33,-49.78) and (457.99,-50.26) .. (462.11,-49.68)
 .. controls (466.24,-49.10) and (464.61,-49.10) .. (469.51,-48.53)
 .. controls (474.40,-47.95) and (474.31,-49.58) .. (480.16,-48.62)
 .. controls (486.02,-47.66) and (484.19,-46.89) .. (488.23,-47.37)
 .. controls (492.26,-47.85) and (489.38,-48.23) .. (495.52,-48.05)
 .. controls (501.67,-47.86) and (497.82,-48.05) .. (503.97,-47.76)
 .. controls (510.11,-47.48) and (509.35,-47.58) .. (514.05,-47.77)
 .. controls (518.75,-47.96) and (516.26,-48.25) .. (521.06,-48.06)
 .. controls (525.86,-47.87) and (521.83,-47.39) .. (527.11,-47.77)
 .. controls (532.39,-48.15) and (532.39,-48.06) .. (535.27,-48.15)
 .. controls (538.15,-48.25) and (534.79,-48.92) .. (539.87,-47.96)
 .. controls (544.96,-47.00) and (544.48,-46.81) .. (546.98,-46.90)
 .. controls (549.47,-47.00) and (550.72,-47.57) .. (556.77,-47.19)
 .. controls (562.82,-46.81) and (560.80,-46.81) .. (565.31,-46.90)
 .. controls (569.83,-47.00) and (563.39,-47.48) .. (571.36,-46.90)
 .. controls (579.33,-46.33) and (575.97,-46.23) .. (581.63,-46.04)
 .. controls (587.30,-45.85) and (585.76,-45.85) .. (591.14,-45.65)
 .. controls (596.51,-45.46) and (593.25,-45.46) .. (598.34,-45.46)
 .. controls (603.43,-45.46) and (599.49,-45.75) .. (605.35,-45.37)
 .. controls (611.20,-44.98) and (608.13,-45.08) .. (613.31,-44.79)
 .. controls (618.50,-44.50) and (619.84,-45.36) .. (623.11,-44.40)
 .. controls (626.37,-43.44) and (623.39,-43.54) .. (629.06,-42.38)
 .. controls (634.72,-41.23) and (631.84,-41.52) .. (637.12,-40.85)
 .. controls (642.40,-40.17) and (638.85,-40.56) .. (644.03,-39.89)
 .. controls (649.22,-39.22) and (647.30,-39.60) .. (652.19,-39.03)
 .. controls (657.09,-38.45) and (655.46,-37.87) .. (660.07,-38.26)
 .. controls (664.67,-38.64) and (661.79,-38.16) .. (667.17,-38.84)
 .. controls (672.55,-39.51) and (671.68,-39.22) .. (675.71,-39.60)
 .. controls (679.75,-39.99) and (679.36,-40.28) .. (682.92,-40.18)
 .. controls (686.47,-40.08) and (697.80,-40.37) .. (699.43,-40.37)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((699.43,-40.37)
 .. controls (699.43,-40.37) and (699.71,-39.98) .. (703.36,-39.40)
 .. controls (707.01,-38.83) and (705.28,-38.73) .. (709.79,-38.73)
 .. controls (714.30,-38.73) and (713.25,-39.02) .. (717.28,-38.73)
 .. controls (721.31,-38.45) and (721.79,-37.97) .. (725.54,-37.97)
 .. controls (729.28,-37.97) and (727.65,-38.45) .. (732.06,-37.97)
 .. controls (736.48,-37.49) and (736.10,-37.88) .. (740.32,-38.17)
 .. controls (744.54,-38.46) and (743.87,-38.36) .. (746.94,-38.55)
 .. controls (750.02,-38.75) and (750.02,-39.04) .. (754.14,-39.13)
 .. controls (758.27,-39.23) and (755.10,-39.13) .. (762.21,-39.42)
 .. controls (769.31,-39.71) and (769.98,-39.42) .. (775.55,-38.94)
 .. controls (781.12,-38.46) and (782.18,-38.55) .. (789.86,-37.59)
 .. controls (797.54,-36.63) and (796.86,-37.59) .. (800.32,-36.06)
 .. controls (803.78,-34.52) and (800.80,-34.43) .. (807.14,-33.37)
 .. controls (813.47,-32.31) and (810.98,-32.31) .. (814.53,-32.02)
 .. controls (818.08,-31.74) and (815.20,-31.16) .. (820.48,-31.64)
 .. controls (825.76,-32.12) and (824.42,-32.41) .. (830.08,-32.69)
 .. controls (835.75,-32.98) and (834.21,-32.69) .. (839.20,-33.36)
 .. controls (844.19,-34.04) and (850.24,-34.71) .. (852.54,-34.42)
 .. controls (854.85,-34.13) and (855.90,-33.27) .. (860.61,-33.75)
 .. controls (865.31,-34.23) and (865.02,-33.94) .. (870.40,-33.85)
 .. controls (875.78,-33.75) and (872.70,-34.33) .. (879.04,-34.04)
 .. controls (885.38,-33.76) and (882.11,-34.33) .. (887.78,-33.76)
 .. controls (893.44,-33.18) and (890.85,-33.09) .. (895.84,-33.28)
 .. controls (900.83,-33.47) and (897.86,-33.95) .. (904.00,-33.57)
 .. controls (910.14,-33.18) and (917.15,-32.89) .. (919.94,-32.60)
 .. controls (922.72,-32.32) and (923.39,-32.70) .. (926.85,-32.80)
 .. controls (930.31,-32.89) and (929.06,-32.70) .. (932.80,-32.50)
 .. controls (936.55,-32.31) and (936.93,-32.12) .. (939.04,-32.02)
 .. controls (941.15,-31.92) and (941.15,-31.25) .. (945.57,-31.73)
 .. controls (949.98,-32.21) and (953.92,-33.65) .. (956.80,-33.46)
 .. controls (959.68,-33.27) and (959.10,-33.17) .. (963.14,-33.37)
 .. controls (967.17,-33.56) and (965.63,-33.75) .. (970.14,-33.75)
 .. controls (974.66,-33.75) and (971.78,-33.47) .. (976.67,-33.66)
 .. controls (981.57,-33.85) and (979.84,-34.62) .. (985.70,-33.66)
 .. controls (991.55,-32.70) and (991.84,-33.18) .. (995.78,-32.98)
 .. controls (999.71,-32.79) and (1000.10,-32.79) .. (1004.23,-33.08)
 .. controls (1008.35,-33.36) and (1007.30,-32.79) .. (1012.00,-33.17)
 .. controls (1016.70,-33.55) and (1018.82,-33.46) .. (1022.46,-33.46)
 .. controls (1026.11,-33.46) and (1024.86,-33.84) .. (1030.24,-33.46)
 .. controls (1035.62,-33.07) and (1034.56,-32.59) .. (1040.32,-32.88)
 .. controls (1046.08,-33.17) and (1046.08,-34.03) .. (1051.36,-33.46)
 .. controls (1056.64,-32.88) and (1057.12,-32.40) .. (1060.67,-32.50)
 .. controls (1064.22,-32.59) and (1061.92,-32.98) .. (1067.10,-32.59)
 .. controls (1072.29,-32.21) and (1073.06,-32.21) .. (1077.76,-32.31)
 .. controls (1082.46,-32.40) and (1081.02,-32.40) .. (1084.67,-32.40)
 .. controls (1088.32,-32.40) and (1091.01,-33.17) .. (1094.66,-32.69)
 .. controls (1098.30,-32.21) and (1102.91,-30.48) .. (1110.30,-30.96)
 .. controls (1117.70,-31.44) and (1117.60,-32.21) .. (1122.21,-32.31)
 .. controls (1126.82,-32.40) and (1123.17,-31.73) .. (1128.16,-32.31)
 .. controls (1133.15,-32.88) and (1129.98,-33.65) .. (1135.07,-33.27)
 .. controls (1140.16,-32.88) and (1138.82,-32.12) .. (1143.23,-32.79)
 .. controls (1147.65,-33.46) and (1146.59,-34.04) .. (1150.81,-33.46)
 .. controls (1155.04,-32.89) and (1154.75,-32.79) .. (1158.97,-32.89)
 .. controls (1163.20,-32.99) and (1161.09,-32.79) .. (1166.27,-32.99)
 .. controls (1171.46,-33.18) and (1176.35,-33.17) .. (1178.37,-32.98)
 .. controls (1180.39,-32.79) and (1186.53,-34.60) .. (1191.81,-34.22)
 .. controls (1197.09,-33.83) and (1193.34,-34.03) .. (1199.87,-34.22)
 .. controls (1206.40,-34.41) and (1204.96,-34.61) .. (1208.61,-34.41)
 .. controls (1212.25,-34.22) and (1210.05,-34.70) .. (1215.33,-34.13)
 .. controls (1220.61,-33.55) and (1220.51,-33.74) .. (1224.35,-33.94)
 .. controls (1228.19,-34.13) and (1228.19,-34.90) .. (1232.13,-34.13)
 .. controls (1236.06,-33.36) and (1234.81,-33.75) .. (1237.79,-33.27)
 .. controls (1240.77,-32.79) and (1239.33,-33.27) .. (1244.41,-32.50)
 .. controls (1249.50,-31.73) and (1246.53,-32.11) .. (1252.29,-31.35)
 .. controls (1258.05,-30.58) and (1261.98,-30.77) .. (1263.42,-31.06)
 .. controls (1264.86,-31.35) and (1269.76,-31.74) .. (1272.93,-31.93)
 .. controls (1276.09,-32.12) and (1274.65,-31.64) .. (1281.85,-32.41)
 .. controls (1289.05,-33.18) and (1286.17,-33.28) .. (1292.13,-33.18)
 .. controls (1298.08,-33.09) and (1295.58,-32.51) .. (1299.52,-33.09)
 .. controls (1303.46,-33.66) and (1301.44,-33.86) .. (1306.05,-34.05)
 .. controls (1310.66,-34.24) and (1310.46,-34.53) .. (1314.78,-34.14)
 .. controls (1319.10,-33.75) and (1319.49,-33.95) .. (1322.75,-33.56)
 .. controls (1326.02,-33.18) and (1324.38,-33.18) .. (1329.76,-32.89)
 .. controls (1335.14,-32.60) and (1335.90,-32.41) .. (1338.69,-32.12)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1338.69,-32.12)
 .. controls (1338.69,-32.12) and (1341.95,-31.44) .. (1344.54,-31.44)
 .. controls (1347.13,-31.44) and (1348.38,-32.02) .. (1352.80,-31.83)
 .. controls (1357.21,-31.64) and (1356.25,-31.44) .. (1362.30,-31.06)
 .. controls (1368.35,-30.68) and (1364.13,-31.06) .. (1370.27,-30.48)
 .. controls (1376.41,-29.91) and (1376.61,-29.53) .. (1380.54,-29.53)
 .. controls (1384.48,-29.53) and (1380.73,-29.72) .. (1387.17,-29.53)
 .. controls (1393.60,-29.33) and (1390.24,-28.66) .. (1396.19,-28.47)
 .. controls (1402.14,-28.28) and (1410.88,-29.43) .. (1415.01,-27.61)
 .. controls (1419.13,-25.79) and (1416.83,-26.27) .. (1421.73,-25.11)
 .. controls (1426.62,-23.96) and (1422.88,-24.83) .. (1427.97,-23.68)
 .. controls (1433.05,-22.52) and (1431.52,-22.62) .. (1436.51,-21.95)
 .. controls (1441.50,-21.28) and (1438.81,-21.09) .. (1444.09,-21.09)
 .. controls (1449.37,-21.09) and (1450.62,-20.99) .. (1456.09,-20.80)
 .. controls (1461.57,-20.61) and (1460.22,-20.32) .. (1466.75,-21.09)
 .. controls (1473.28,-21.85) and (1478.56,-21.37) .. (1481.06,-21.47)
 .. controls (1483.55,-21.57) and (1488.06,-23.87) .. (1492.19,-24.06)
 .. controls (1496.32,-24.25) and (1492.86,-24.26) .. (1497.95,-24.35)
 .. controls (1503.04,-24.44) and (1507.46,-24.15) .. (1513.70,-23.67)
 .. controls (1519.94,-23.19) and (1515.42,-23.58) .. (1523.10,-23.19)
 .. controls (1530.78,-22.81) and (1529.82,-22.90) .. (1533.66,-22.62)
 .. controls (1537.50,-22.33) and (1533.57,-22.52) .. (1538.66,-22.23)
 .. controls (1543.74,-21.94) and (1541.15,-21.65) .. (1546.24,-22.23)
 .. controls (1551.33,-22.81) and (1554.69,-23.77) .. (1559.68,-23.96)
 .. controls (1564.67,-24.16) and (1561.50,-24.16) .. (1566.88,-24.54)
 .. controls (1572.26,-24.93) and (1572.93,-25.02) .. (1576.77,-24.83)
 .. controls (1580.61,-24.64) and (1579.36,-24.35) .. (1584.06,-24.35)
 .. controls (1588.77,-24.36) and (1586.46,-24.16) .. (1592.42,-24.26)
 .. controls (1598.37,-24.35) and (1594.72,-24.93) .. (1600.58,-24.16)
 .. controls (1606.43,-23.39) and (1604.51,-25.22) .. (1609.89,-24.35)
 .. controls (1615.26,-23.49) and (1610.56,-22.82) .. (1617.66,-23.39)
 .. controls (1624.77,-23.97) and (1625.73,-24.93) .. (1632.16,-24.54)
 .. controls (1638.59,-24.16) and (1638.59,-24.35) .. (1645.22,-23.78)
 .. controls (1651.84,-23.20) and (1652.90,-23.20) .. (1658.66,-23.39)
 .. controls (1664.42,-23.58) and (1670.75,-24.06) .. (1673.82,-23.97)
 .. controls (1676.90,-23.87) and (1692.64,-23.10) .. (1692.64,-23.10)
 .. controls (1692.64,-23.10) and (1694.18,-23.49) .. (1699.94,-23.58)
 .. controls (1705.70,-23.68) and (1707.04,-23.58) .. (1711.17,-23.49)
 .. controls (1715.30,-23.39) and (1717.12,-23.49) .. (1720.00,-23.58)
 .. controls (1722.88,-23.68) and (1721.25,-23.49) .. (1726.34,-23.77)
 .. controls (1731.42,-24.06) and (1736.03,-25.02) .. (1740.06,-24.25)
 .. controls (1744.10,-23.49) and (1741.31,-23.29) .. (1749.18,-23.39)
 .. controls (1757.06,-23.49) and (1758.21,-23.68) .. (1760.13,-23.68)
 .. controls (1762.05,-23.68) and (1759.17,-23.58) .. (1767.52,-23.39)
 .. controls (1775.87,-23.20) and (1774.91,-23.10) .. (1779.14,-23.10)
 .. controls (1783.36,-23.10) and (1781.82,-23.10) .. (1785.57,-23.01)
 .. controls (1789.31,-22.91) and (1787.97,-23.68) .. (1793.54,-22.81)
 .. controls (1799.11,-21.95) and (1800.07,-22.71) .. (1803.81,-21.75)
 .. controls (1807.55,-20.79) and (1806.11,-20.31) .. (1810.53,-20.50)
 .. controls (1814.95,-20.69) and (1819.46,-20.40) .. (1821.38,-19.64)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1821.38,-19.64)
 .. controls (1821.38,-19.64) and (1824.06,-19.06) .. (1827.33,-19.16)
 .. controls (1830.59,-19.25) and (1831.84,-20.12) .. (1835.39,-19.54)
 .. controls (1838.94,-18.96) and (1839.71,-19.54) .. (1843.26,-18.39)
 .. controls (1846.82,-17.24) and (1846.14,-17.52) .. (1849.41,-16.76)
 .. controls (1852.67,-15.99) and (1853.63,-16.56) .. (1856.51,-15.89)
 .. controls (1859.39,-15.22) and (1859.58,-14.55) .. (1863.23,-14.36)
 .. controls (1866.88,-14.17) and (1862.75,-14.74) .. (1868.61,-14.17)
 .. controls (1874.46,-13.60) and (1871.10,-13.60) .. (1876.38,-13.60)
 .. controls (1881.67,-13.60) and (1877.54,-13.31) .. (1882.24,-13.59)
 .. controls (1886.95,-13.88) and (1889.35,-13.97) .. (1890.98,-14.07)
 .. controls (1892.61,-14.16) and (1892.23,-14.07) .. (1895.01,-13.97)
 .. controls (1897.79,-13.87) and (1897.70,-13.68) .. (1900.19,-13.68)
 .. controls (1902.69,-13.68) and (1906.24,-14.16) .. (1907.10,-14.36)
 .. controls (1907.97,-14.55) and (1907.30,-14.26) .. (1910.65,-14.55)
 .. controls (1914.01,-14.84) and (1913.82,-14.84) .. (1916.89,-14.84)
 .. controls (1919.97,-14.84) and (1917.28,-14.65) .. (1921.79,-14.84)
 .. controls (1926.30,-15.04) and (1925.44,-15.13) .. (1929.95,-15.13)
 .. controls (1934.46,-15.13) and (1933.89,-15.13) .. (1938.11,-14.65)
 .. controls (1942.34,-14.17) and (1937.25,-13.78) .. (1943.97,-14.07)
 .. controls (1950.69,-14.36) and (1950.40,-15.03) .. (1953.95,-15.22)
 .. controls (1957.50,-15.41) and (1953.18,-15.51) .. (1959.23,-15.51)
 .. controls (1965.28,-15.51) and (1966.14,-15.60) .. (1969.98,-15.79)
 .. controls (1973.82,-15.99) and (1972.19,-16.56) .. (1976.80,-16.18)
 .. controls (1981.41,-15.79) and (1979.01,-16.08) .. (1982.94,-15.60)
 .. controls (1986.88,-15.12) and (1988.70,-14.93) .. (1989.38,-15.02)
 .. controls (1990.05,-15.12) and (1991.20,-15.41) .. (1996.38,-15.02)
 .. controls (2001.57,-14.64) and (2002.34,-14.93) .. (2008.10,-14.93)
 .. controls (2013.86,-14.93) and (2010.59,-14.64) .. (2016.26,-14.64)
 .. controls (2021.92,-14.64) and (2022.11,-14.93) .. (2027.30,-14.35)
 .. controls (2032.48,-13.77) and (2035.07,-14.16) .. (2042.08,-13.39)
 .. controls (2049.09,-12.62) and (2045.25,-12.33) .. (2051.20,-12.33)
 .. controls (2057.15,-12.33) and (2065.50,-11.56) .. (2067.33,-11.66)
 .. controls (2069.15,-11.76) and (2072.99,-12.81) .. (2078.85,-12.62)
 .. controls (2084.70,-12.43) and (2093.25,-13.29) .. (2097.76,-13.29)
 .. controls (2102.27,-13.29) and (2096.99,-13.39) .. (2103.71,-13.10)
 .. controls (2110.43,-12.82) and (2107.65,-13.01) .. (2114.65,-12.91)
 .. controls (2121.66,-12.82) and (2121.85,-12.62) .. (2124.54,-12.82)
 .. controls (2127.23,-13.01) and (2127.52,-13.78) .. (2131.36,-13.39)
 .. controls (2135.20,-13.01) and (2133.18,-12.43) .. (2139.04,-12.24)
 .. controls (2144.90,-12.05) and (2146.82,-11.95) .. (2147.78,-12.05)
 .. controls (2148.74,-12.14) and (2151.52,-12.05) .. (2156.42,-12.62)
 .. controls (2161.31,-13.20) and (2164.58,-14.35) .. (2167.45,-14.16)
 .. controls (2170.33,-13.96) and (2167.65,-13.77) .. (2174.65,-13.48)
 .. controls (2181.66,-13.20) and (2183.20,-12.81) .. (2186.94,-12.81)
 .. controls (2190.69,-12.81) and (2190.59,-12.62) .. (2195.97,-13.00)
 .. controls (2201.34,-13.39) and (2201.63,-14.16) .. (2204.80,-13.96)
 .. controls (2207.97,-13.77) and (2204.32,-13.87) .. (2210.17,-13.29)
 .. controls (2216.03,-12.72) and (2217.47,-12.72) .. (2220.93,-12.33)
 .. controls (2224.38,-11.95) and (2228.13,-13.10) .. (2233.02,-13.01)
 .. controls (2237.92,-12.91) and (2236.10,-13.39) .. (2243.58,-12.81)
 .. controls (2251.07,-12.24) and (2247.42,-12.33) .. (2254.82,-11.76)
 .. controls (2262.21,-11.18) and (2258.18,-11.38) .. (2264.80,-11.18)
 .. controls (2271.42,-10.99) and (2262.50,-11.18) .. (2274.21,-10.80)
 .. controls (2285.92,-10.42) and (2284.10,-10.42) .. (2289.09,-10.42)
 .. controls (2294.08,-10.42) and (2288.32,-10.04) .. (2294.75,-10.23)
 .. controls (2301.18,-10.42) and (2300.03,-10.33) .. (2302.72,-10.42)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((2302.72,-10.42)
 .. controls (2302.72,-10.42) and (2308.10,-10.81) .. (2313.66,-10.71)
 .. controls (2319.23,-10.62) and (2316.83,-10.42) .. (2322.30,-10.42)
 .. controls (2327.78,-10.42) and (2324.32,-11.19) .. (2330.08,-10.52)
 .. controls (2335.84,-9.85) and (2334.98,-9.75) .. (2339.68,-9.75)
 .. controls (2344.38,-9.75) and (2342.18,-9.27) .. (2348.61,-9.75)
 .. controls (2355.04,-10.23) and (2354.75,-11.48) .. (2360.90,-11.00)
 .. controls (2367.04,-10.52) and (2365.98,-10.33) .. (2370.59,-10.61)
 .. controls (2375.20,-10.90) and (2375.20,-11.19) .. (2377.79,-11.29)
 .. controls (2380.38,-11.38) and (2392.58,-12.73) .. (2394.98,-13.02)
 .. controls (2397.38,-13.30) and (2397.66,-13.40) .. (2401.98,-13.59)
 .. controls (2406.30,-13.78) and (2402.37,-13.59) .. (2409.28,-13.50)
 .. controls (2416.19,-13.40) and (2414.85,-13.40) .. (2421.86,-13.88)
 .. controls (2428.86,-14.36) and (2429.73,-15.32) .. (2433.66,-15.22)
 .. controls (2437.60,-15.13) and (2434.14,-14.46) .. (2440.48,-14.84)
 .. controls (2446.82,-15.22) and (2448.64,-15.90) .. (2454.98,-16.09)
 .. controls (2461.31,-16.28) and (2464.19,-16.47) .. (2467.36,-16.76)
 .. controls (2470.53,-17.05) and (2474.47,-16.95) .. (2480.13,-15.51)
 .. controls (2485.79,-14.06) and (2484.93,-13.39) .. (2490.30,-13.39)
 .. controls (2495.68,-13.39) and (2492.32,-14.83) .. (2498.46,-13.01)
 .. controls (2504.61,-11.18) and (2500.29,-12.14) .. (2507.39,-10.51)
 .. controls (2514.49,-8.88) and (2511.81,-9.26) .. (2517.09,-8.30)
 .. controls (2522.37,-7.34) and (2519.49,-8.02) .. (2525.44,-6.86)
 .. controls (2531.39,-5.71) and (2533.02,-5.42) .. (2535.71,-5.33)
 .. controls (2538.40,-5.23) and (2541.18,-4.94) .. (2544.54,-4.85)
 .. controls (2547.90,-4.75) and (2552.13,-3.79) .. (2552.13,-3.79)
));
ATTR__stationflag_splay := false;
drawoptions();
p_station((2135.75,-9.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2521.68,-2.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2476.12,-4.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2465.69,-6.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2459.20,-6.12),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2429.94,-8.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2377.15,-9.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2329.79,-8.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2234.73,-10.24),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2192.02,-10.11),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2167.74,8.36),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((2065.47,-8.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1974.45,-13.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1921.81,-13.07),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1897.72,-11.18),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1875.31,-10.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1852.67,-13.38),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1818.92,-16.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1787.84,-21.26),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1600.65,-19.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1591.13,-19.42),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1544.66,-21.07),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1514.03,-19.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1494.14,-22.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1442.94,-19.01),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1398.85,-22.67),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1349.26,-29.97),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1301.12,-30.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1246.95,-30.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1216.12,-30.31),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1190.58,-29.21),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1171.81,-30.23),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1163.68,-29.70),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1138.65,-29.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1091.76,-30.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((1009.97,-29.70),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((983.74,-31.14),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((943.39,-27.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((925.94,-28.61),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((893.29,-31.74),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((846.49,-31.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((798.32,-30.93),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((748.60,-36.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((710.92,-35.67),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((673.90,-35.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((636.92,-37.55),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((601.40,-40.00),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((584.05,-41.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((550.26,-45.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((515.70,-46.64),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((489.14,-45.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((428.42,-47.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((381.14,-49.19),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((341.80,-56.25),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((272.78,-55.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((247.08,-57.86),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((212.83,-55.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((168.91,-59.20),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((129.72,-59.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((115.63,-60.56),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((89.25,-63.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((17.61,-64.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-23.44,-66.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-96.38,-66.52),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-127.75,-66.29),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-161.29,-68.08),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-192.62,-69.90),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-208.47,-65.85),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-245.31,-70.45),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-285.17,-68.65),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-319.66,-73.70),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-349.92,-75.89),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-374.53,-74.91),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-424.85,-72.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-465.02,-72.39),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-486.23,-72.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-546.92,-78.27),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-607.05,-78.76),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-659.70,-77.17),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-677.35,-76.78),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-695.61,-77.33),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-763.88,-78.46),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-824.45,-79.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-881.36,-78.80),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-926.44,-68.10),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-985.67,-71.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1028.96,-79.35),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1089.60,-82.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1147.57,-81.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1154.80,-71.69),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1179.15,-81.54),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1192.99,-84.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1248.95,-84.05),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1273.84,-84.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1319.34,-85.49),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1329.78,-84.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1353.12,-84.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1401.27,-84.79),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1457.35,-84.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1504.47,-84.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1562.74,-84.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1626.05,-83.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1688.26,-84.66),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1738.12,-76.00),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1798.60,-81.63),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1845.92,-82.99),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1872.88,-87.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1912.43,-82.37),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1925.11,-86.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-1965.58,-95.92),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2002.80,-97.53),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2043.39,-96.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2070.18,-97.43),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2071.25,-98.77),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2107.51,-98.62),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2121.72,-97.02),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2136.02,-97.47),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2150.62,-95.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2160.61,-97.09),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2168.23,-97.00),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2190.57,-94.58),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2200.05,-99.06),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2215.74,-97.98),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2253.18,-98.34),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2286.70,-95.15),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2324.60,-95.03),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2485.28,-98.24),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2352.58,-94.20),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2511.24,-96.28),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2532.73,-96.26),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2391.30,-94.84),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2558.27,-94.13),1,btex \thcomment \thfb\char72 \char101 \char108 \char105 \char99 \char111 \char112 \char116 \char101 \char114 \ \char72 \char111 \char108 \char101 \mainfont{} etex,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2441.67,-93.41),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2509.65,-93.96),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2482.97,-94.22),1,0,"");
ATTR__stationflag_splay := false;
drawoptions();
p_station((-2435.71,-96.17),1,0,"");
endfig;
beginfig(7);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char84 \char104 \char101 \ \char76 \char105 \char98 \char114 \char97 \char114 \char121 \mainfont{} etex,(1837.22,-40.95),0.0,0);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char72 \char101 \char108 \char101 \char99 \char111 \char112 \char116 \char101 \char114 \ \char68 \char111 \char108 \char105 \char110 \char101 \mainfont{} etex,(-2400.00,-123.45),0.0,0);
endfig;
beginfig(8);
s_northarrow(0);
endfig;
beginfig(9);
s_scalebar(100, 1, "\thfb\char109 \mainfont{}");
endfig;
Scale:=5.00;
initialize(Scale);
background:=(1.00000,1.00000,1.00000);
transparency:=false;
end;
