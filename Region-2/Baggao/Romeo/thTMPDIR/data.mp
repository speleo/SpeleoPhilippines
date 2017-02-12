Scale:=2.00;
MagDecl:=-2.84;
GridConv:=0.30;
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
ATTR__elevation:=false;

% user defined symbols defaults
% end of user defined symbols

defaultfont:="cmss10";
NorthDir:="true";
def a_water (expr p) =
T:=identity;
thfill p withcolor (0.1, 0.2, 0.8);
enddef;
def a_sump (expr p) =
T:=identity;
thfill p withcolor (0.1, 0.2, 0.8);
enddef;
def l_survey_cave (expr p) =
draw p withpen PenD withcolor (0.6, 0.6, 0.6);
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
background:=(0.99250,0.25000,1.00000);
def_transparent_rgb(tr_bg, 0.99250, 0.25000, 1.00000);
current_scrap := "romeo_cathedralSP1@romeo_cathedral.romeo";
ATTR__scrap := "romeo_cathedralSP1";
beginfig(1);
ATTR__survey := "romeo_cathedral.romeo";
current_src := "romeo_cathedral.th2 [68]";
string area_border[];
area_border[1] := "l26-1151-724";
area_border[2] := "l19-1169-483";
area_border[3] := "l27-1080-289";
area_border[4] := "l23-876-347";
drawoptions();
a_water(buildcycle(((-11.84,26.19)
 .. controls (-11.84,26.19) and (-13.65,82.64) .. (-53.94,72.91)
 .. controls (-93.77,63.28) and (-129.07,50.12) .. (-117.69,25.76)
 .. controls (-106.26,1.29) and (-96.31,-1.29) .. (-94.51,-1.47)
),
((-27.22,-15.62)
 .. controls (-28.54,-0.30) and (-11.84,26.19) .. (-11.84,26.19)
),
((-59.76,-23.14)
 .. controls (-59.76,-23.14) and (-30.36,-19.56) .. (-27.22,-15.62)
),
((-94.51,-1.47)
 .. controls (-94.51,-1.47) and (-85.36,5.42) .. (-73.27,-6.16)
 .. controls (-61.22,-17.70) and (-57.31,-15.65) .. (-59.76,-23.14)
)));
current_src := "romeo_cathedral.th2 [61]";
string area_border[];
area_border[1] := "l20-1268-555";
area_border[2] := "l19-1169-483";
area_border[3] := "l21-1235-272";
area_border[4] := "l18-1356-360";
drawoptions();
a_sand(buildcycle(((34.48,13.62)
 .. controls (30.45,38.35) and (-11.84,26.19) .. (-11.84,26.19)
),
((-27.22,-15.62)
 .. controls (-28.54,-0.30) and (-11.84,26.19) .. (-11.84,26.19)
),
((-27.22,-15.62)
 .. controls (-30.75,-14.65) and (15.39,-27.46) .. (15.39,-27.46)
),
((15.39,-27.46)
 .. controls (8.95,5.55) and (34.48,13.62) .. (34.48,13.62)
)));
current_src := "romeo_cathedral.th2 [28]";
string area_border[];
area_border[1] := "l15-1671-305";
area_border[2] := "l14-1561-252";
area_border[3] := "l16-1543-92";
drawoptions();
a_water(buildcycle(((62.35,-16.51)
 .. controls (62.35,-16.51) and (82.42,-7.85) .. (94.23,-18.92)
),
((62.35,-16.51)
 .. controls (62.35,-16.51) and (49.73,-27.13) .. (46.48,-45.66)
),
((46.48,-45.66)
 .. controls (46.48,-45.66) and (52.23,-66.96) .. (64.78,-82.37)
)));
ATTR__height := -1;
drawoptions();
l_floorstep(((-94.13,-6.01)
 .. controls (-94.13,-6.01) and (-83.98,-19.64) .. (-70.12,-25.60)
));
ATTR__id := "l23-876-347";
ATTR__height := -1;
drawoptions();
l_flowstone(((-94.51,-1.47)
 .. controls (-94.51,-1.47) and (-85.36,5.42) .. (-73.27,-6.16)
 .. controls (-61.22,-17.70) and (-57.31,-15.65) .. (-59.76,-23.14)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-161.73,0.31)
 .. controls (-161.73,0.31) and (-158.79,-12.74) .. (-163.49,-16.84)
 .. controls (-168.20,-20.95) and (-150.90,-20.32) .. (-152.85,-28.29)
));
ATTR__id := "l26-1151-724";
ATTR__height := -1;
drawoptions();
l_border_visible(((-11.84,26.19)
 .. controls (-11.84,26.19) and (-13.65,82.64) .. (-53.94,72.91)
 .. controls (-93.77,63.28) and (-129.07,50.12) .. (-117.69,25.76)
 .. controls (-106.26,1.29) and (-96.31,-1.29) .. (-94.51,-1.47)
));
ATTR__id := "l27-1080-289";
ATTR__height := -1;
drawoptions();
l_border_visible(((-59.76,-23.14)
 .. controls (-59.76,-23.14) and (-30.36,-19.56) .. (-27.22,-15.62)
));
ATTR__id := "l19-1169-483";
ATTR__height := -1;
drawoptions();
l_floorstep(((-27.22,-15.62)
 .. controls (-28.54,-0.30) and (-11.84,26.19) .. (-11.84,26.19)
));
ATTR__id := "l14-1561-252";
ATTR__height := -1;
drawoptions();
l_floorstep(((62.35,-16.51)
 .. controls (62.35,-16.51) and (49.73,-27.13) .. (46.48,-45.66)
));
ATTR__id := "l15-1671-305";
ATTR__height := -1;
drawoptions();
l_border_visible(((62.35,-16.51)
 .. controls (62.35,-16.51) and (82.42,-7.85) .. (94.23,-18.92)
));
ATTR__id := "l16-1543-92";
ATTR__height := -1;
drawoptions();
l_border_visible(((46.48,-45.66)
 .. controls (46.48,-45.66) and (52.23,-66.96) .. (64.78,-82.37)
));
ATTR__id := "l18-1356-360";
ATTR__height := -1;
drawoptions();
l_pit(((15.39,-27.46)
 .. controls (8.95,5.55) and (34.48,13.62) .. (34.48,13.62)
));
ATTR__id := "l21-1235-272";
ATTR__height := -1;
drawoptions();
l_border_visible(((-27.22,-15.62)
 .. controls (-30.75,-14.65) and (15.39,-27.46) .. (15.39,-27.46)
));
ATTR__id := "l20-1268-555";
ATTR__height := -1;
drawoptions();
l_floorstep(((34.48,13.62)
 .. controls (30.45,38.35) and (-11.84,26.19) .. (-11.84,26.19)
));
endfig;
beginfig(2);
draw_upscrap(1)(1,((85.97,-15.89)
 .. controls (85.97,-15.89) and (71.20,-18.15) .. (67.19,-17.26)
 .. controls (63.08,-16.35) and (50.59,-13.63) .. (45.16,-3.56)
 .. controls (39.80,6.39) and (35.58,12.00) .. (34.48,13.62)
 .. controls (33.38,15.25) and (21.80,22.36) .. (16.85,23.13)
 .. controls (11.89,23.91) and (-0.54,26.96) .. (-4.37,26.29)
 .. controls (-8.20,25.61) and (-15.47,25.32) .. (-17.85,29.87)
 .. controls (-20.25,34.45) and (-24.82,47.36) .. (-25.04,49.93)
 .. controls (-25.26,52.50) and (-28.43,60.01) .. (-29.53,61.84)
 .. controls (-30.63,63.66) and (-30.81,67.48) .. (-39.66,67.47)
 .. controls (-48.44,67.47) and (-54.68,64.46) .. (-58.94,62.05)
 .. controls (-63.19,59.63) and (-75.41,49.45) .. (-81.11,48.30)
 .. controls (-86.82,47.15) and (-98.28,46.16) .. (-102.76,45.78)
 .. controls (-107.25,45.40) and (-112.83,46.30) .. (-112.65,41.07)
 .. controls (-112.46,35.84) and (-111.55,28.44) .. (-109.56,23.92)
 .. controls (-107.56,19.39) and (-103.57,12.32) .. (-100.86,8.69)
 .. controls (-98.14,5.06) and (-95.79,3.61) .. (-95.78,0.53)
 .. controls (-95.76,-2.56) and (-88.72,-7.84) .. (-100.98,-6.35)
 .. controls (-105.03,-5.85) and (-107.68,-4.32) .. (-112.20,-4.09)
 .. controls (-116.73,-3.87) and (-125.63,-3.75) .. (-129.82,-3.14)
 .. controls (-134.01,-2.53) and (-155.90,-0.15) .. (-159.91,0.46)
 .. controls (-163.91,1.06) and (-174.25,4.06) .. (-179.86,3.73)
 .. controls (-185.45,3.40) and (-191.21,5.01) .. (-190.68,1.78)
 .. controls (-190.14,-1.46) and (-186.51,-13.21) .. (-184.32,-17.56)
 .. controls (-182.12,-21.94) and (-178.98,-29.94) .. (-167.21,-29.72)
 .. controls (-155.39,-29.49) and (-147.22,-26.75) .. (-140.64,-29.41)
 .. controls (-134.07,-32.07) and (-121.14,-33.73) .. (-115.52,-33.62)
 .. controls (-109.90,-33.50) and (-88.59,-30.91) .. (-84.28,-29.28)
 .. controls (-79.97,-27.64) and (-58.15,-22.05) .. (-50.87,-20.46)
 .. controls (-43.60,-18.87) and (-25.79,-14.17) .. (-17.31,-16.08)
 .. controls (-8.57,-18.04) and (1.76,-20.81) .. (4.86,-21.56)
 .. controls (7.89,-22.29) and (20.06,-29.58) .. (26.09,-34.41)
 .. controls (32.44,-39.50) and (40.54,-45.93) .. (42.83,-45.73)
 .. controls (45.20,-45.52) and (56.38,-50.57) .. (60.19,-52.97)
 .. controls (63.48,-55.05) and (63.99,-50.63) .. (66.18,-60.34)
 .. controls (68.47,-70.54) and (66.38,-75.97) .. (68.14,-78.59)
));
draw_downscrap;
endfig;
beginfig(3);
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((85.97,-15.89)
 .. controls (85.97,-15.89) and (71.20,-18.15) .. (67.19,-17.26)
 .. controls (63.08,-16.35) and (50.59,-13.63) .. (45.16,-3.56)
 .. controls (39.80,6.39) and (35.58,12.00) .. (34.48,13.62)
 .. controls (33.38,15.25) and (21.80,22.36) .. (16.85,23.13)
 .. controls (11.89,23.91) and (-0.54,26.96) .. (-4.37,26.29)
 .. controls (-8.20,25.61) and (-15.47,25.32) .. (-17.85,29.87)
 .. controls (-20.25,34.45) and (-24.82,47.36) .. (-25.04,49.93)
 .. controls (-25.26,52.50) and (-28.43,60.01) .. (-29.53,61.84)
 .. controls (-30.63,63.66) and (-30.81,67.48) .. (-39.66,67.47)
 .. controls (-48.44,67.47) and (-54.68,64.46) .. (-58.94,62.05)
 .. controls (-63.19,59.63) and (-75.41,49.45) .. (-81.11,48.30)
 .. controls (-86.82,47.15) and (-98.28,46.16) .. (-102.76,45.78)
 .. controls (-107.25,45.40) and (-112.83,46.30) .. (-112.65,41.07)
 .. controls (-112.46,35.84) and (-111.55,28.44) .. (-109.56,23.92)
 .. controls (-107.56,19.39) and (-103.57,12.32) .. (-100.86,8.69)
 .. controls (-98.14,5.06) and (-95.79,3.61) .. (-95.78,0.53)
 .. controls (-95.76,-2.56) and (-88.72,-7.84) .. (-100.98,-6.35)
 .. controls (-105.03,-5.85) and (-107.68,-4.32) .. (-112.20,-4.09)
 .. controls (-116.73,-3.87) and (-125.63,-3.75) .. (-129.82,-3.14)
 .. controls (-134.01,-2.53) and (-155.90,-0.15) .. (-159.91,0.46)
 .. controls (-163.91,1.06) and (-174.25,4.06) .. (-179.86,3.73)
 .. controls (-185.45,3.40) and (-191.21,5.01) .. (-190.68,1.78)
 .. controls (-190.14,-1.46) and (-186.51,-13.21) .. (-184.32,-17.56)
 .. controls (-182.12,-21.94) and (-178.98,-29.94) .. (-167.21,-29.72)
 .. controls (-155.39,-29.49) and (-147.22,-26.75) .. (-140.64,-29.41)
 .. controls (-134.07,-32.07) and (-121.14,-33.73) .. (-115.52,-33.62)
 .. controls (-109.90,-33.50) and (-88.59,-30.91) .. (-84.28,-29.28)
 .. controls (-79.97,-27.64) and (-58.15,-22.05) .. (-50.87,-20.46)
 .. controls (-43.60,-18.87) and (-25.79,-14.17) .. (-17.31,-16.08)
 .. controls (-8.57,-18.04) and (1.76,-20.81) .. (4.86,-21.56)
 .. controls (7.89,-22.29) and (20.06,-29.58) .. (26.09,-34.41)
 .. controls (32.44,-39.50) and (40.54,-45.93) .. (42.83,-45.73)
 .. controls (45.20,-45.52) and (56.38,-50.57) .. (60.19,-52.97)
 .. controls (63.48,-55.05) and (63.99,-50.63) .. (66.18,-60.34)
 .. controls (68.47,-70.54) and (66.38,-75.97) .. (68.14,-78.59)
));
drawoptions();
p_rimstonepool((48.82,-17.96),226.4,1.00,(0,0));
drawoptions();
p_rimstonepool((46.66,-27.17),234.0,1.00,(0,0));
drawoptions();
p_rimstonepool((40.15,-35.30),244.6,1.00,(0,0));
drawoptions();
p_rimstonepool((27.35,-29.57),240.4,1.00,(0,0));
drawoptions();
p_rimstonepool((37.03,-20.91),223.1,1.00,(0,0));
drawoptions();
p_rimstonepool((23.08,-21.42),245.4,1.00,(0,0));
drawoptions();
p_rimstonepool((34.59,-11.66),243.6,1.00,(0,0));
drawoptions();
p_rimstonepool((39.12,-3.72),220.5,1.00,(0,0));
drawoptions();
p_rimstonepool((24.75,-9.39),222.7,1.00,(0,0));
drawoptions();
p_rimstonepool((27.49,2.55),232.5,1.00,(0,0));
endfig;
beginfig(4);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char49 \char54 \mainfont{} etex,(-31.03,-31.44),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char83 \char117 \char109 \char112 \mainfont{} etex,(-107.99,61.64),0.0,0);
endfig;
background:=(0.37000,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.37000, 1.00000, 0.25000);
current_scrap := "romeoSP4@romeo_entrance.romeo";
ATTR__scrap := "romeoSP4";
beginfig(5);
ATTR__survey := "romeo_entrance.romeo";
current_src := "Romeo_entrance.th2 [1538]";
string area_border[];
area_border[1] := "l688-9440-19696";
area_border[2] := "l607-9326-19350";
area_border[3] := "l183-9896-18512";
area_border[4] := "l608-9224-17162";
area_border[5] := "l187-8364-15472";
area_border[6] := "l609-8620-15342";
area_border[7] := "l184-9852-17572";
area_border[8] := "l610-10188-18254";
drawoptions();
a_water(buildcycle(((515.58,1191.51)
 -- (554.45,1268.54)
),
((515.58,1191.51)
 -- (520.44,1030.95)
),
((498.30,776.98)
 .. controls (501.35,779.50) and (512.33,786.33) .. (516.47,793.35)
 .. controls (520.61,800.37) and (522.77,814.05) .. (525.65,822.51)
 .. controls (528.53,830.97) and (531.95,831.51) .. (538.62,834.93)
 .. controls (545.28,838.35) and (561.48,852.39) .. (565.80,856.00)
 .. controls (570.12,859.60) and (588.84,882.46) .. (592.80,888.57)
 .. controls (596.76,894.69) and (610.08,918.63) .. (612.42,930.33)
 .. controls (614.76,942.03) and (613.14,987.93) .. (612.06,992.25)
 .. controls (610.98,996.57) and (607.74,1010.43) .. (606.12,1022.67)
 .. controls (604.50,1034.91) and (597.12,1060.29) .. (594.06,1066.23)
 .. controls (591.00,1072.17) and (581.64,1080.09) .. (574.07,1082.43)
 .. controls (566.51,1084.77) and (553.73,1070.55) .. (550.68,1067.31)
 .. controls (547.62,1064.07) and (538.44,1050.39) .. (536.46,1045.71)
 .. controls (534.48,1041.03) and (521.88,1032.21) .. (520.44,1030.95)
),
((498.30,776.98)
 .. controls (498.30,776.98) and (302.11,539.57) .. (328.38,502.84)
),
((328.38,502.84)
 .. controls (329.46,498.88) and (333.42,487.72) .. (333.42,476.56)
 .. controls (333.42,465.40) and (329.46,454.59) .. (331.62,446.31)
 .. controls (333.78,438.03) and (331.26,428.67) .. (333.78,420.03)
 .. controls (336.30,411.39) and (334.50,402.75) .. (338.46,398.79)
 .. controls (342.42,394.83) and (351.79,390.88) .. (355.03,387.64)
),
((355.03,387.64)
 -- (412.97,505.52)
),
((650.22,875.44)
 .. controls (648.06,873.10) and (627.90,857.62) .. (621.60,852.22)
 .. controls (615.30,846.82) and (595.68,837.28) .. (592.08,830.44)
 .. controls (588.48,823.60) and (582.18,814.96) .. (579.84,808.48)
 .. controls (577.50,802.00) and (579.11,791.02) .. (578.03,785.79)
 .. controls (576.95,780.57) and (577.13,773.19) .. (573.35,762.39)
 .. controls (569.57,751.59) and (561.65,738.45) .. (559.85,731.07)
 .. controls (558.05,723.69) and (549.77,716.13) .. (546.89,708.93)
 .. controls (544.01,701.73) and (534.65,688.77) .. (531.59,685.17)
 .. controls (528.53,681.57) and (502.80,655.30) .. (499.20,648.46)
 .. controls (495.60,641.62) and (474.72,613.91) .. (470.58,608.68)
 .. controls (466.44,603.46) and (458.34,587.62) .. (455.46,580.78)
 .. controls (452.58,573.94) and (451.32,571.41) .. (445.74,566.55)
 .. controls (440.16,561.69) and (434.22,554.85) .. (429.36,548.73)
 .. controls (424.50,542.61) and (417.12,530.91) .. (416.22,526.05)
 .. controls (415.31,521.19) and (413.51,510.21) .. (412.97,505.52)
),
((650.22,875.44)
 -- (669.67,1016.56)
 -- (721.15,1179.29)
 -- (554.45,1268.54)
)));
current_src := "Romeo_entrance.th2 [1514]";
string area_border[];
area_border[1] := "l29-9392-18376";
area_border[2] := "l187-8364-15472";
area_border[3] := "l30-9984-17468";
area_border[4] := "l189-8350-14756";
area_border[5] := "l189-8350-14756";
drawoptions();
a_blocks(buildcycle(((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
),
((328.38,502.84)
 .. controls (329.46,498.88) and (333.42,487.72) .. (333.42,476.56)
 .. controls (333.42,465.40) and (329.46,454.59) .. (331.62,446.31)
 .. controls (333.78,438.03) and (331.26,428.67) .. (333.78,420.03)
 .. controls (336.30,411.39) and (334.50,402.75) .. (338.46,398.79)
 .. controls (342.42,394.83) and (351.79,390.88) .. (355.03,387.64)
),
((29.03,-396.81)
 .. controls (33.17,-388.16) and (25.98,-371.59) .. (33.91,-351.41)
 .. controls (41.83,-331.25) and (51.91,-313.25) .. (48.30,-291.66)
 .. controls (44.70,-270.06) and (41.81,-243.43) .. (38.21,-232.64)
 .. controls (34.60,-221.85) and (35.33,-199.52) .. (36.06,-186.55)
 .. controls (36.78,-173.59) and (35.35,-149.82) .. (46.87,-132.54)
 .. controls (58.39,-115.26) and (72.07,-80.71) .. (92.23,-64.86)
 .. controls (112.39,-49.02) and (153.42,-6.56) .. (160.62,6.40)
 .. controls (167.82,19.37) and (204.56,52.51) .. (210.32,65.47)
 .. controls (216.08,78.43) and (239.12,122.34) .. (242.71,133.86)
 .. controls (246.31,145.37) and (252.78,214.47) .. (294.55,245.45)
 .. controls (336.31,276.42) and (336.31,313.85) .. (342.07,323.93)
 .. controls (347.83,334.01) and (350.71,386.56) .. (350.70,390.88)
 .. controls (350.70,395.20) and (352.86,418.96) .. (361.50,434.08)
 .. controls (370.14,449.20) and (385.26,470.07) .. (392.45,480.87)
 .. controls (399.65,491.66) and (416.21,523.35) .. (421.98,529.83)
 .. controls (427.74,536.31) and (454.38,554.31) .. (463.02,564.40)
 .. controls (471.66,574.48) and (545.10,654.40) .. (551.57,666.64)
 .. controls (558.05,678.87) and (563.81,701.91) .. (568.13,713.43)
 .. controls (572.45,724.95) and (583.97,735.03) .. (590.45,744.40)
 .. controls (596.93,753.76) and (617.82,779.68) .. (617.82,790.48)
 .. controls (617.82,801.28) and (626.46,830.80) .. (636.54,847.36)
 .. controls (646.62,863.92) and (650.94,902.80) .. (650.94,908.56)
 .. controls (650.94,914.32) and (656.71,962.56) .. (654.55,974.79)
 .. controls (652.38,987.03) and (644.46,1010.07) .. (653.11,1029.52)
 .. controls (661.75,1048.96) and (676.87,1077.76) .. (683.35,1089.28)
 .. controls (689.83,1100.80) and (705.67,1128.17) .. (704.23,1140.41)
 .. controls (702.79,1152.65) and (700.81,1174.79) .. (674.88,1181.98)
 .. controls (648.96,1189.18) and (612.78,1192.96) .. (600.54,1192.23)
 .. controls (588.30,1191.51) and (559.50,1186.47) .. (544.38,1205.19)
 .. controls (529.26,1223.90) and (532.86,1215.27) .. (530.70,1221.03)
),
((289.86,386.55)
 .. controls (289.86,386.55) and (297.06,353.08) .. (295.98,342.99)
 .. controls (294.90,332.91) and (290.93,310.95) .. (291.30,304.47)
 .. controls (291.66,297.99) and (286.26,291.16) .. (296.70,294.76)
 .. controls (307.14,298.36) and (318.66,312.40) .. (321.54,317.44)
 .. controls (324.42,322.48) and (332.34,332.92) .. (337.03,340.12)
 .. controls (341.71,347.32) and (352.51,354.53) .. (352.51,354.53)
),
((289.86,386.55)
 .. controls (289.86,386.55) and (297.06,353.08) .. (295.98,342.99)
 .. controls (294.90,332.91) and (290.93,310.95) .. (291.30,304.47)
 .. controls (291.66,297.99) and (286.26,291.16) .. (296.70,294.76)
 .. controls (307.14,298.36) and (318.66,312.40) .. (321.54,317.44)
 .. controls (324.42,322.48) and (332.34,332.92) .. (337.03,340.12)
 .. controls (341.71,347.32) and (352.51,354.53) .. (352.51,354.53)
)));
current_src := "Romeo_entrance.th2 [1448]";
string area_border[];
area_border[1] := "l30-9984-17468";
area_border[2] := "l54-5320-8936";
area_border[3] := "l200-6296-10916";
area_border[4] := "l196-6316-11828";
area_border[5] := "l197-6472-11896";
drawoptions();
a_water(buildcycle(((29.03,-396.81)
 .. controls (33.17,-388.16) and (25.98,-371.59) .. (33.91,-351.41)
 .. controls (41.83,-331.25) and (51.91,-313.25) .. (48.30,-291.66)
 .. controls (44.70,-270.06) and (41.81,-243.43) .. (38.21,-232.64)
 .. controls (34.60,-221.85) and (35.33,-199.52) .. (36.06,-186.55)
 .. controls (36.78,-173.59) and (35.35,-149.82) .. (46.87,-132.54)
 .. controls (58.39,-115.26) and (72.07,-80.71) .. (92.23,-64.86)
 .. controls (112.39,-49.02) and (153.42,-6.56) .. (160.62,6.40)
 .. controls (167.82,19.37) and (204.56,52.51) .. (210.32,65.47)
 .. controls (216.08,78.43) and (239.12,122.34) .. (242.71,133.86)
 .. controls (246.31,145.37) and (252.78,214.47) .. (294.55,245.45)
 .. controls (336.31,276.42) and (336.31,313.85) .. (342.07,323.93)
 .. controls (347.83,334.01) and (350.71,386.56) .. (350.70,390.88)
 .. controls (350.70,395.20) and (352.86,418.96) .. (361.50,434.08)
 .. controls (370.14,449.20) and (385.26,470.07) .. (392.45,480.87)
 .. controls (399.65,491.66) and (416.21,523.35) .. (421.98,529.83)
 .. controls (427.74,536.31) and (454.38,554.31) .. (463.02,564.40)
 .. controls (471.66,574.48) and (545.10,654.40) .. (551.57,666.64)
 .. controls (558.05,678.87) and (563.81,701.91) .. (568.13,713.43)
 .. controls (572.45,724.95) and (583.97,735.03) .. (590.45,744.40)
 .. controls (596.93,753.76) and (617.82,779.68) .. (617.82,790.48)
 .. controls (617.82,801.28) and (626.46,830.80) .. (636.54,847.36)
 .. controls (646.62,863.92) and (650.94,902.80) .. (650.94,908.56)
 .. controls (650.94,914.32) and (656.71,962.56) .. (654.55,974.79)
 .. controls (652.38,987.03) and (644.46,1010.07) .. (653.11,1029.52)
 .. controls (661.75,1048.96) and (676.87,1077.76) .. (683.35,1089.28)
 .. controls (689.83,1100.80) and (705.67,1128.17) .. (704.23,1140.41)
 .. controls (702.79,1152.65) and (700.81,1174.79) .. (674.88,1181.98)
 .. controls (648.96,1189.18) and (612.78,1192.96) .. (600.54,1192.23)
 .. controls (588.30,1191.51) and (559.50,1186.47) .. (544.38,1205.19)
 .. controls (529.26,1223.90) and (532.86,1215.27) .. (530.70,1221.03)
),
((-490.14,-1005.77)
 .. controls (-488.04,-1003.16) and (-483.47,-997.22) .. (-478.68,-993.90)
 .. controls (-473.86,-990.56) and (-465.78,-987.89) .. (-461.10,-987.15)
 .. controls (-456.40,-986.41) and (-436.69,-978.70) .. (-433.44,-976.89)
 .. controls (-430.21,-975.09) and (-412.45,-964.77) .. (-407.98,-960.48)
 .. controls (-403.49,-956.19) and (-395.38,-937.10) .. (-392.84,-930.04)
 .. controls (-390.31,-923.00) and (-384.92,-907.71) .. (-383.85,-902.33)
 .. controls (-382.79,-896.96) and (-381.56,-883.51) .. (-380.66,-878.65)
 .. controls (-379.76,-873.79) and (-376.15,-864.77) .. (-373.44,-859.54)
 .. controls (-370.73,-854.31) and (-362.24,-844.36) .. (-355.56,-838.93)
 .. controls (-348.88,-833.50) and (-334.99,-824.45) .. (-331.21,-822.28)
 .. controls (-327.42,-820.11) and (-318.59,-811.81) .. (-315.89,-808.03)
 .. controls (-313.19,-804.25) and (-303.28,-791.64) .. (-299.68,-788.93)
 .. controls (-296.07,-786.23) and (-283.64,-771.45) .. (-279.85,-768.74)
 .. controls (-276.07,-766.04) and (-260.76,-752.52) .. (-252.84,-743.88)
 .. controls (-244.93,-735.25) and (-234.50,-726.27) .. (-228.21,-723.58)
 .. controls (-221.91,-720.89) and (-201.25,-707.27) .. (-197.30,-703.68)
 .. controls (-193.35,-700.10) and (-165.83,-679.08) .. (-159.53,-673.86)
 .. controls (-153.23,-668.64) and (-134.16,-653.88) .. (-127.86,-649.03)
 .. controls (-121.56,-644.17) and (-85.09,-607.21) .. (-80.78,-603.25)
 .. controls (-76.46,-599.30) and (-70.70,-581.48) .. (-67.81,-573.37)
 .. controls (-64.92,-565.26) and (-50.86,-541.81) .. (-48.87,-537.67)
 .. controls (-46.89,-533.53) and (-25.11,-491.77) .. (-21.87,-486.74)
 .. controls (-18.63,-481.70) and (-9.45,-470.36) .. (-6.93,-466.40)
 .. controls (-4.42,-462.44) and (15.90,-432.24) .. (17.34,-425.59)
 .. controls (18.77,-418.94) and (27.41,-401.85) .. (29.03,-396.81)
),
((-40.98,-308.22)
 .. controls (-40.98,-308.22) and (-38.10,-322.97) .. (-38.81,-336.65)
 .. controls (-39.52,-350.32) and (-41.32,-374.79) .. (-38.44,-382.35)
 .. controls (-35.56,-389.91) and (-30.88,-388.11) .. (-34.84,-396.39)
 .. controls (-38.80,-404.67) and (-59.33,-425.92) .. (-65.82,-439.62)
 .. controls (-72.32,-453.32) and (-75.92,-469.88) .. (-75.92,-478.87)
 .. controls (-75.91,-487.86) and (-91.72,-531.01) .. (-97.48,-538.58)
 .. controls (-103.24,-546.14) and (-106.86,-562.00) .. (-109.74,-573.89)
 .. controls (-112.62,-585.76) and (-112.97,-603.39) .. (-118.72,-606.62)
 .. controls (-124.47,-609.84) and (-128.43,-610.91) .. (-137.42,-610.55)
 .. controls (-146.42,-610.18) and (-154.34,-612.70) .. (-165.51,-618.48)
 .. controls (-176.69,-624.27) and (-191.83,-625.75) .. (-198.32,-629.72)
 .. controls (-204.80,-633.69) and (-206.25,-633.32) .. (-208.76,-643.76)
 .. controls (-211.27,-654.18) and (-213.78,-659.21) .. (-213.40,-668.54)
 .. controls (-213.02,-677.86) and (-221.65,-680.00) .. (-212.28,-685.39)
 .. controls (-202.91,-690.78) and (-198.22,-694.00) .. (-192.10,-692.21)
 .. controls (-185.99,-690.41) and (-171.93,-693.98) .. (-171.93,-693.98)
),
((-98.53,-328.31)
 .. controls (-98.53,-328.31) and (-89.54,-328.32) .. (-83.06,-327.60)
 .. controls (-76.59,-326.89) and (-64.72,-325.46) .. (-60.76,-324.39)
 .. controls (-56.80,-323.31) and (-39.18,-313.98) .. (-32.34,-309.31)
 .. controls (-25.51,-304.64) and (-17.24,-293.48) .. (-16.51,-285.20)
 .. controls (-15.79,-276.91) and (-15.07,-268.99) .. (-13.62,-258.18)
 .. controls (-12.18,-247.38) and (-12.54,-231.90) .. (-14.34,-222.90)
 .. controls (-16.14,-213.90) and (-23.33,-204.90) .. (-28.01,-202.38)
 .. controls (-32.69,-199.86) and (-47.81,-188.70) .. (-47.81,-188.70)
),
((-27.29,-209.21)
 .. controls (-21.89,-204.90) and (-21.89,-197.34) .. (-18.66,-193.74)
 .. controls (-15.42,-190.15) and (-2.82,-183.67) .. (1.50,-180.43)
 .. controls (5.82,-177.19) and (5.10,-173.95) .. (11.94,-173.23)
 .. controls (18.78,-172.51) and (38.22,-177.19) .. (40.74,-179.71)
)));
current_src := "Romeo_entrance.th2 [1428]";
string area_border[];
area_border[1] := "l30-9984-17468";
area_border[2] := "l194-6756-12360";
area_border[3] := "l195-6512-12060";
area_border[4] := "l29-9392-18376";
area_border[5] := "l192-7526-13736";
area_border[6] := "l29-9392-18376";
area_border[7] := "l191-7944-14488";
area_border[8] := "l189-8350-14756";
drawoptions();
a_water(buildcycle(((29.03,-396.81)
 .. controls (33.17,-388.16) and (25.98,-371.59) .. (33.91,-351.41)
 .. controls (41.83,-331.25) and (51.91,-313.25) .. (48.30,-291.66)
 .. controls (44.70,-270.06) and (41.81,-243.43) .. (38.21,-232.64)
 .. controls (34.60,-221.85) and (35.33,-199.52) .. (36.06,-186.55)
 .. controls (36.78,-173.59) and (35.35,-149.82) .. (46.87,-132.54)
 .. controls (58.39,-115.26) and (72.07,-80.71) .. (92.23,-64.86)
 .. controls (112.39,-49.02) and (153.42,-6.56) .. (160.62,6.40)
 .. controls (167.82,19.37) and (204.56,52.51) .. (210.32,65.47)
 .. controls (216.08,78.43) and (239.12,122.34) .. (242.71,133.86)
 .. controls (246.31,145.37) and (252.78,214.47) .. (294.55,245.45)
 .. controls (336.31,276.42) and (336.31,313.85) .. (342.07,323.93)
 .. controls (347.83,334.01) and (350.71,386.56) .. (350.70,390.88)
 .. controls (350.70,395.20) and (352.86,418.96) .. (361.50,434.08)
 .. controls (370.14,449.20) and (385.26,470.07) .. (392.45,480.87)
 .. controls (399.65,491.66) and (416.21,523.35) .. (421.98,529.83)
 .. controls (427.74,536.31) and (454.38,554.31) .. (463.02,564.40)
 .. controls (471.66,574.48) and (545.10,654.40) .. (551.57,666.64)
 .. controls (558.05,678.87) and (563.81,701.91) .. (568.13,713.43)
 .. controls (572.45,724.95) and (583.97,735.03) .. (590.45,744.40)
 .. controls (596.93,753.76) and (617.82,779.68) .. (617.82,790.48)
 .. controls (617.82,801.28) and (626.46,830.80) .. (636.54,847.36)
 .. controls (646.62,863.92) and (650.94,902.80) .. (650.94,908.56)
 .. controls (650.94,914.32) and (656.71,962.56) .. (654.55,974.79)
 .. controls (652.38,987.03) and (644.46,1010.07) .. (653.11,1029.52)
 .. controls (661.75,1048.96) and (676.87,1077.76) .. (683.35,1089.28)
 .. controls (689.83,1100.80) and (705.67,1128.17) .. (704.23,1140.41)
 .. controls (702.79,1152.65) and (700.81,1174.79) .. (674.88,1181.98)
 .. controls (648.96,1189.18) and (612.78,1192.96) .. (600.54,1192.23)
 .. controls (588.30,1191.51) and (559.50,1186.47) .. (544.38,1205.19)
 .. controls (529.26,1223.90) and (532.86,1215.27) .. (530.70,1221.03)
),
((93.32,-74.22)
 .. controls (91.52,-74.94) and (74.95,-76.39) .. (71.35,-81.07)
 .. controls (67.75,-85.75) and (63.07,-88.99) .. (54.43,-94.03)
 .. controls (45.79,-99.07) and (41.10,-100.51) .. (37.15,-106.99)
 .. controls (33.19,-113.47) and (32.47,-120.30) .. (32.83,-126.78)
 .. controls (33.19,-133.26) and (29.23,-137.94) .. (29.23,-143.34)
 .. controls (29.23,-148.74) and (29.95,-150.90) .. (31.39,-153.42)
 .. controls (32.83,-155.94) and (42.19,-164.94) .. (42.19,-164.94)
),
((-17.22,-122.47)
 .. controls (-17.22,-126.43) and (-17.58,-140.12) .. (-16.14,-142.64)
 .. controls (-14.70,-145.16) and (-16.51,-152.37) .. (-10.38,-154.16)
 .. controls (-4.26,-155.96) and (9.78,-157.03) .. (14.46,-155.59)
 .. controls (19.15,-154.15) and (23.83,-151.27) .. (25.99,-151.26)
 .. controls (28.15,-151.26) and (33.91,-150.18) .. (33.91,-150.18)
),
((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
),
((12.30,-65.23)
 .. controls (14.46,-65.23) and (51.90,-51.20) .. (63.07,-40.76)
 .. controls (74.23,-30.31) and (93.67,-15.91) .. (103.75,-9.43)
 .. controls (113.83,-2.95) and (122.47,-1.15) .. (128.22,1.37)
 .. controls (133.98,3.88) and (143.34,25.85) .. (143.71,32.69)
 .. controls (144.07,39.53) and (148.03,58.26) .. (151.63,70.50)
 .. controls (155.23,82.73) and (159.19,94.25) .. (162.06,102.89)
 .. controls (164.94,111.52) and (172.50,129.52) .. (176.46,136.73)
 .. controls (180.43,143.93) and (194.11,173.45) .. (195.91,183.53)
 .. controls (197.71,193.61) and (193.03,217.73) .. (191.59,223.85)
 .. controls (190.15,229.97) and (185.84,244.74) .. (184.76,246.90)
),
((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
),
((199.51,256.62)
 .. controls (205.27,260.57) and (231.91,270.65) .. (236.23,272.09)
 .. controls (240.55,273.53) and (270.42,286.48) .. (275.10,288.64)
 .. controls (279.78,290.80) and (293.46,295.48) .. (293.46,295.48)
),
((289.86,386.55)
 .. controls (289.86,386.55) and (297.06,353.08) .. (295.98,342.99)
 .. controls (294.90,332.91) and (290.93,310.95) .. (291.30,304.47)
 .. controls (291.66,297.99) and (286.26,291.16) .. (296.70,294.76)
 .. controls (307.14,298.36) and (318.66,312.40) .. (321.54,317.44)
 .. controls (324.42,322.48) and (332.34,332.92) .. (337.03,340.12)
 .. controls (341.71,347.32) and (352.51,354.53) .. (352.51,354.53)
)));
current_src := "Romeo_entrance.th2 [1419]";
string area_border[];
area_border[1] := "l195-6512-12060";
area_border[2] := "l194-6756-12360";
area_border[3] := "l30-9984-17468";
area_border[4] := "l197-6472-11896";
area_border[5] := "l196-6316-11828";
area_border[6] := "l29-9392-18376";
drawoptions();
a_blocks(buildcycle(((-17.22,-122.47)
 .. controls (-17.22,-126.43) and (-17.58,-140.12) .. (-16.14,-142.64)
 .. controls (-14.70,-145.16) and (-16.51,-152.37) .. (-10.38,-154.16)
 .. controls (-4.26,-155.96) and (9.78,-157.03) .. (14.46,-155.59)
 .. controls (19.15,-154.15) and (23.83,-151.27) .. (25.99,-151.26)
 .. controls (28.15,-151.26) and (33.91,-150.18) .. (33.91,-150.18)
),
((93.32,-74.22)
 .. controls (91.52,-74.94) and (74.95,-76.39) .. (71.35,-81.07)
 .. controls (67.75,-85.75) and (63.07,-88.99) .. (54.43,-94.03)
 .. controls (45.79,-99.07) and (41.10,-100.51) .. (37.15,-106.99)
 .. controls (33.19,-113.47) and (32.47,-120.30) .. (32.83,-126.78)
 .. controls (33.19,-133.26) and (29.23,-137.94) .. (29.23,-143.34)
 .. controls (29.23,-148.74) and (29.95,-150.90) .. (31.39,-153.42)
 .. controls (32.83,-155.94) and (42.19,-164.94) .. (42.19,-164.94)
),
((29.03,-396.81)
 .. controls (33.17,-388.16) and (25.98,-371.59) .. (33.91,-351.41)
 .. controls (41.83,-331.25) and (51.91,-313.25) .. (48.30,-291.66)
 .. controls (44.70,-270.06) and (41.81,-243.43) .. (38.21,-232.64)
 .. controls (34.60,-221.85) and (35.33,-199.52) .. (36.06,-186.55)
 .. controls (36.78,-173.59) and (35.35,-149.82) .. (46.87,-132.54)
 .. controls (58.39,-115.26) and (72.07,-80.71) .. (92.23,-64.86)
 .. controls (112.39,-49.02) and (153.42,-6.56) .. (160.62,6.40)
 .. controls (167.82,19.37) and (204.56,52.51) .. (210.32,65.47)
 .. controls (216.08,78.43) and (239.12,122.34) .. (242.71,133.86)
 .. controls (246.31,145.37) and (252.78,214.47) .. (294.55,245.45)
 .. controls (336.31,276.42) and (336.31,313.85) .. (342.07,323.93)
 .. controls (347.83,334.01) and (350.71,386.56) .. (350.70,390.88)
 .. controls (350.70,395.20) and (352.86,418.96) .. (361.50,434.08)
 .. controls (370.14,449.20) and (385.26,470.07) .. (392.45,480.87)
 .. controls (399.65,491.66) and (416.21,523.35) .. (421.98,529.83)
 .. controls (427.74,536.31) and (454.38,554.31) .. (463.02,564.40)
 .. controls (471.66,574.48) and (545.10,654.40) .. (551.57,666.64)
 .. controls (558.05,678.87) and (563.81,701.91) .. (568.13,713.43)
 .. controls (572.45,724.95) and (583.97,735.03) .. (590.45,744.40)
 .. controls (596.93,753.76) and (617.82,779.68) .. (617.82,790.48)
 .. controls (617.82,801.28) and (626.46,830.80) .. (636.54,847.36)
 .. controls (646.62,863.92) and (650.94,902.80) .. (650.94,908.56)
 .. controls (650.94,914.32) and (656.71,962.56) .. (654.55,974.79)
 .. controls (652.38,987.03) and (644.46,1010.07) .. (653.11,1029.52)
 .. controls (661.75,1048.96) and (676.87,1077.76) .. (683.35,1089.28)
 .. controls (689.83,1100.80) and (705.67,1128.17) .. (704.23,1140.41)
 .. controls (702.79,1152.65) and (700.81,1174.79) .. (674.88,1181.98)
 .. controls (648.96,1189.18) and (612.78,1192.96) .. (600.54,1192.23)
 .. controls (588.30,1191.51) and (559.50,1186.47) .. (544.38,1205.19)
 .. controls (529.26,1223.90) and (532.86,1215.27) .. (530.70,1221.03)
),
((-27.29,-209.21)
 .. controls (-21.89,-204.90) and (-21.89,-197.34) .. (-18.66,-193.74)
 .. controls (-15.42,-190.15) and (-2.82,-183.67) .. (1.50,-180.43)
 .. controls (5.82,-177.19) and (5.10,-173.95) .. (11.94,-173.23)
 .. controls (18.78,-172.51) and (38.22,-177.19) .. (40.74,-179.71)
),
((-98.53,-328.31)
 .. controls (-98.53,-328.31) and (-89.54,-328.32) .. (-83.06,-327.60)
 .. controls (-76.59,-326.89) and (-64.72,-325.46) .. (-60.76,-324.39)
 .. controls (-56.80,-323.31) and (-39.18,-313.98) .. (-32.34,-309.31)
 .. controls (-25.51,-304.64) and (-17.24,-293.48) .. (-16.51,-285.20)
 .. controls (-15.79,-276.91) and (-15.07,-268.99) .. (-13.62,-258.18)
 .. controls (-12.18,-247.38) and (-12.54,-231.90) .. (-14.34,-222.90)
 .. controls (-16.14,-213.90) and (-23.33,-204.90) .. (-28.01,-202.38)
 .. controls (-32.69,-199.86) and (-47.81,-188.70) .. (-47.81,-188.70)
),
((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
)));
current_src := "Romeo_entrance.th2 [1355]";
string area_border[];
area_border[1] := "l624-5116-9242";
drawoptions();
a_blocks(buildcycle(((-392.90,-699.27)
 -- (-377.48,-709.81)
 -- (-350.12,-701.88)
 -- (-343.34,-725.39)
 -- (-294.64,-772.74)
 -- (-268.69,-752.53)
 -- (-220.49,-710.49)
 -- (-226.69,-677.84)
 -- (-251.87,-660.89)
 -- (-270.19,-659.39)
 -- (-301.10,-674.43)
 -- (-343.22,-682.36)
 -- (-373.43,-675.46)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1329]";
string area_border[];
area_border[1] := "l627-5152-9338";
drawoptions();
a_sand(buildcycle(((-383.55,-697.49)
 .. controls (-383.55,-697.49) and (-385.66,-679.79) .. (-363.38,-682.71)
 .. controls (-341.07,-685.63) and (-330.28,-688.85) .. (-314.42,-681.64)
 .. controls (-298.58,-674.43) and (-271.26,-660.46) .. (-260.13,-654.75)
 .. controls (-249.01,-649.04) and (-241.83,-638.29) .. (-223.87,-636.90)
 .. controls (-205.88,-635.50) and (-212.01,-640.16) .. (-217.74,-657.76)
 .. controls (-223.46,-675.33) and (-221.28,-682.15) .. (-217.31,-689.69)
 .. controls (-213.33,-697.22) and (-206.13,-696.15) .. (-203.60,-702.96)
 .. controls (-201.06,-709.78) and (-203.52,-742.79) .. (-212.14,-750.33)
 .. controls (-220.78,-757.88) and (-280.92,-794.64) .. (-280.92,-794.64)
 .. controls (-280.92,-794.64) and (-321.73,-764.59) .. (-328.22,-749.50)
 .. controls (-334.72,-734.40) and (-343.68,-715.26) .. (-350.86,-708.40)
 .. controls (-358.04,-701.52) and (-371.73,-708.74) .. (-378.18,-703.66)
 .. controls (-384.63,-698.58) and (-383.55,-697.49) .. cycle
)));
current_src := "Romeo_entrance.th2 [1306]";
string area_border[];
area_border[1] := "l630-6180-10998";
drawoptions();
a_blocks(buildcycle(((-166.56,-567.67)
 .. controls (-166.56,-567.67) and (-181.24,-581.41) .. (-181.69,-582.08)
 .. controls (-194.32,-601.21) and (-205.86,-607.72) .. (-193.26,-616.73)
 .. controls (-180.67,-625.73) and (-140.66,-605.14) .. (-136.34,-603.71)
 .. controls (-132.03,-602.28) and (-115.49,-582.52) .. (-108.64,-547.21)
 .. controls (-101.80,-511.93) and (-73.04,-465.20) .. (-71.59,-447.19)
 .. controls (-70.14,-429.16) and (-43.11,-398.54) .. (-49.95,-380.54)
 .. controls (-56.79,-362.54) and (-51.76,-344.91) .. (-71.19,-342.73)
 .. controls (-90.62,-340.55) and (-84.86,-341.28) .. (-95.65,-362.50)
 .. controls (-106.45,-383.74) and (-121.57,-396.69) .. (-126.25,-404.97)
 .. controls (-130.93,-413.25) and (-167.63,-506.80) .. (-167.63,-506.80)
 .. controls (-167.63,-506.80) and (-161.51,-508.25) .. (-159.36,-541.74)
 .. controls (-158.98,-547.54) and (-162.60,-560.11) .. (-162.60,-560.11)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1295]";
string area_border[];
area_border[1] := "l29-9392-18376";
area_border[2] := "l192-7526-13736";
drawoptions();
a_blocks(buildcycle(((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
),
((12.30,-65.23)
 .. controls (14.46,-65.23) and (51.90,-51.20) .. (63.07,-40.76)
 .. controls (74.23,-30.31) and (93.67,-15.91) .. (103.75,-9.43)
 .. controls (113.83,-2.95) and (122.47,-1.15) .. (128.22,1.37)
 .. controls (133.98,3.88) and (143.34,25.85) .. (143.71,32.69)
 .. controls (144.07,39.53) and (148.03,58.26) .. (151.63,70.50)
 .. controls (155.23,82.73) and (159.19,94.25) .. (162.06,102.89)
 .. controls (164.94,111.52) and (172.50,129.52) .. (176.46,136.73)
 .. controls (180.43,143.93) and (194.11,173.45) .. (195.91,183.53)
 .. controls (197.71,193.61) and (193.03,217.73) .. (191.59,223.85)
 .. controls (190.15,229.97) and (185.84,244.74) .. (184.76,246.90)
)));
current_src := "Romeo_entrance.th2 [1270]";
string area_border[];
area_border[1] := "l184-9852-17572";
area_border[2] := "l30-9984-17468";
drawoptions();
a_blocks(buildcycle(((650.22,875.44)
 .. controls (648.06,873.10) and (627.90,857.62) .. (621.60,852.22)
 .. controls (615.30,846.82) and (595.68,837.28) .. (592.08,830.44)
 .. controls (588.48,823.60) and (582.18,814.96) .. (579.84,808.48)
 .. controls (577.50,802.00) and (579.11,791.02) .. (578.03,785.79)
 .. controls (576.95,780.57) and (577.13,773.19) .. (573.35,762.39)
 .. controls (569.57,751.59) and (561.65,738.45) .. (559.85,731.07)
 .. controls (558.05,723.69) and (549.77,716.13) .. (546.89,708.93)
 .. controls (544.01,701.73) and (534.65,688.77) .. (531.59,685.17)
 .. controls (528.53,681.57) and (502.80,655.30) .. (499.20,648.46)
 .. controls (495.60,641.62) and (474.72,613.91) .. (470.58,608.68)
 .. controls (466.44,603.46) and (458.34,587.62) .. (455.46,580.78)
 .. controls (452.58,573.94) and (451.32,571.41) .. (445.74,566.55)
 .. controls (440.16,561.69) and (434.22,554.85) .. (429.36,548.73)
 .. controls (424.50,542.61) and (417.12,530.91) .. (416.22,526.05)
 .. controls (415.31,521.19) and (413.51,510.21) .. (412.97,505.52)
),
((29.03,-396.81)
 .. controls (33.17,-388.16) and (25.98,-371.59) .. (33.91,-351.41)
 .. controls (41.83,-331.25) and (51.91,-313.25) .. (48.30,-291.66)
 .. controls (44.70,-270.06) and (41.81,-243.43) .. (38.21,-232.64)
 .. controls (34.60,-221.85) and (35.33,-199.52) .. (36.06,-186.55)
 .. controls (36.78,-173.59) and (35.35,-149.82) .. (46.87,-132.54)
 .. controls (58.39,-115.26) and (72.07,-80.71) .. (92.23,-64.86)
 .. controls (112.39,-49.02) and (153.42,-6.56) .. (160.62,6.40)
 .. controls (167.82,19.37) and (204.56,52.51) .. (210.32,65.47)
 .. controls (216.08,78.43) and (239.12,122.34) .. (242.71,133.86)
 .. controls (246.31,145.37) and (252.78,214.47) .. (294.55,245.45)
 .. controls (336.31,276.42) and (336.31,313.85) .. (342.07,323.93)
 .. controls (347.83,334.01) and (350.71,386.56) .. (350.70,390.88)
 .. controls (350.70,395.20) and (352.86,418.96) .. (361.50,434.08)
 .. controls (370.14,449.20) and (385.26,470.07) .. (392.45,480.87)
 .. controls (399.65,491.66) and (416.21,523.35) .. (421.98,529.83)
 .. controls (427.74,536.31) and (454.38,554.31) .. (463.02,564.40)
 .. controls (471.66,574.48) and (545.10,654.40) .. (551.57,666.64)
 .. controls (558.05,678.87) and (563.81,701.91) .. (568.13,713.43)
 .. controls (572.45,724.95) and (583.97,735.03) .. (590.45,744.40)
 .. controls (596.93,753.76) and (617.82,779.68) .. (617.82,790.48)
 .. controls (617.82,801.28) and (626.46,830.80) .. (636.54,847.36)
 .. controls (646.62,863.92) and (650.94,902.80) .. (650.94,908.56)
 .. controls (650.94,914.32) and (656.71,962.56) .. (654.55,974.79)
 .. controls (652.38,987.03) and (644.46,1010.07) .. (653.11,1029.52)
 .. controls (661.75,1048.96) and (676.87,1077.76) .. (683.35,1089.28)
 .. controls (689.83,1100.80) and (705.67,1128.17) .. (704.23,1140.41)
 .. controls (702.79,1152.65) and (700.81,1174.79) .. (674.88,1181.98)
 .. controls (648.96,1189.18) and (612.78,1192.96) .. (600.54,1192.23)
 .. controls (588.30,1191.51) and (559.50,1186.47) .. (544.38,1205.19)
 .. controls (529.26,1223.90) and (532.86,1215.27) .. (530.70,1221.03)
)));
current_src := "Romeo_entrance.th2 [1265]";
string area_border[];
area_border[1] := "l29-9392-18376";
area_border[2] := "l183-9896-18512";
drawoptions();
a_blocks(buildcycle(((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
),
((498.30,776.98)
 .. controls (501.35,779.50) and (512.33,786.33) .. (516.47,793.35)
 .. controls (520.61,800.37) and (522.77,814.05) .. (525.65,822.51)
 .. controls (528.53,830.97) and (531.95,831.51) .. (538.62,834.93)
 .. controls (545.28,838.35) and (561.48,852.39) .. (565.80,856.00)
 .. controls (570.12,859.60) and (588.84,882.46) .. (592.80,888.57)
 .. controls (596.76,894.69) and (610.08,918.63) .. (612.42,930.33)
 .. controls (614.76,942.03) and (613.14,987.93) .. (612.06,992.25)
 .. controls (610.98,996.57) and (607.74,1010.43) .. (606.12,1022.67)
 .. controls (604.50,1034.91) and (597.12,1060.29) .. (594.06,1066.23)
 .. controls (591.00,1072.17) and (581.64,1080.09) .. (574.07,1082.43)
 .. controls (566.51,1084.77) and (553.73,1070.55) .. (550.68,1067.31)
 .. controls (547.62,1064.07) and (538.44,1050.39) .. (536.46,1045.71)
 .. controls (534.48,1041.03) and (521.88,1032.21) .. (520.44,1030.95)
)));
current_src := "Romeo_entrance.th2 [1212]";
string area_border[];
area_border[1] := "l241-3598-7320";
area_border[2] := "l96-3588-7456";
drawoptions();
a_water(buildcycle(((-563.18,-964.48)
 .. controls (-563.18,-964.48) and (-564.39,-983.54) .. (-563.93,-991.67)
 .. controls (-563.48,-999.79) and (-563.41,-1004.01) .. (-559.49,-1009.83)
 .. controls (-555.57,-1015.65) and (-551.67,-1019.70) .. (-547.46,-1021.66)
 .. controls (-543.24,-1023.62) and (-537.64,-1023.53) .. (-535.25,-1019.42)
 .. controls (-532.86,-1015.31) and (-532.24,-1009.36) .. (-527.01,-1007.80)
 .. controls (-521.76,-1006.25) and (-517.92,-1003.57) .. (-511.59,-1002.72)
 .. controls (-505.25,-1001.87) and (-498.17,-1002.41) .. (-495.05,-995.75)
 .. controls (-491.90,-989.06) and (-486.23,-984.88) .. (-483.02,-978.46)
 .. controls (-479.79,-971.99) and (-479.04,-965.46) .. (-479.04,-965.46)
),
((-405.75,-816.74)
 .. controls (-402.87,-816.03) and (-399.30,-824.35) .. (-399.13,-828.69)
 .. controls (-398.97,-833.03) and (-400.44,-846.22) .. (-399.91,-849.29)
 .. controls (-399.37,-852.36) and (-393.43,-865.15) .. (-392.35,-869.46)
 .. controls (-391.27,-873.79) and (-402.40,-890.29) .. (-405.44,-895.48)
 .. controls (-408.49,-900.68) and (-421.43,-916.31) .. (-425.76,-923.35)
 .. controls (-430.09,-930.37) and (-441.74,-937.14) .. (-449.45,-942.14)
 .. controls (-457.19,-947.16) and (-464.79,-957.51) .. (-468.78,-961.14)
 .. controls (-472.76,-964.77) and (-487.82,-973.88) .. (-492.63,-975.95)
 .. controls (-497.42,-978.01) and (-523.54,-982.27) .. (-539.33,-986.42)
 .. controls (-555.03,-990.55) and (-555.27,-985.91) .. (-558.09,-984.01)
 .. controls (-560.91,-982.11) and (-563.79,-974.02) .. (-564.70,-970.80)
)));
current_src := "Romeo_entrance.th2 [1203]";
string area_border[];
area_border[1] := "l259-2880-6384";
area_border[2] := "l240-2678-6802";
area_border[3] := "l107-2658-7064";
area_border[4] := "l239-2820-7090";
area_border[5] := "l260-3396-6065";
area_border[6] := "l29-3238-5890";
drawoptions();
a_water(buildcycle(((-677.94,-1112.80)
 .. controls (-675.27,-1110.71) and (-669.69,-1108.80) .. (-663.39,-1108.57)
 .. controls (-657.23,-1108.34) and (-658.20,-1110.22) .. (-649.67,-1108.22)
 .. controls (-641.19,-1106.24) and (-644.11,-1109.62) .. (-643.01,-1112.56)
 .. controls (-641.89,-1115.53) and (-643.33,-1121.83) .. (-643.59,-1127.42)
 .. controls (-643.86,-1133.17) and (-646.64,-1151.99) .. (-647.10,-1155.16)
 .. controls (-647.56,-1158.35) and (-656.18,-1206.80) .. (-658.25,-1218.58)
 .. controls (-660.27,-1230.04) and (-658.75,-1257.37) .. (-657.67,-1261.87)
),
((-692.78,-1042.10)
 .. controls (-692.78,-1042.10) and (-689.47,-1066.67) .. (-686.93,-1073.60)
 .. controls (-684.44,-1080.42) and (-677.69,-1091.75) .. (-672.95,-1096.38)
 .. controls (-668.13,-1101.10) and (-656.88,-1112.96) .. (-654.92,-1114.41)
),
((-616.26,-998.75)
 .. controls (-618.17,-1005.19) and (-635.28,-1015.41) .. (-640.60,-1015.91)
 .. controls (-645.92,-1016.42) and (-665.38,-1016.59) .. (-670.12,-1018.68)
 .. controls (-674.86,-1020.76) and (-687.21,-1043.54) .. (-690.43,-1048.09)
 .. controls (-693.66,-1052.65) and (-699.19,-1059.36) .. (-702.67,-1062.30)
 .. controls (-706.16,-1065.25) and (-719.66,-1075.92) .. (-721.68,-1076.90)
),
((-687.95,-1035.31)
 .. controls (-687.95,-1035.31) and (-683.70,-1037.85) .. (-677.53,-1037.53)
 .. controls (-671.37,-1037.21) and (-657.91,-1039.77) .. (-650.44,-1038.29)
 .. controls (-642.98,-1036.80) and (-633.37,-1037.88) .. (-626.81,-1040.46)
 .. controls (-620.25,-1043.04) and (-610.92,-1047.97) .. (-603.78,-1045.75)
 .. controls (-596.62,-1043.53) and (-587.36,-1041.03) .. (-579.26,-1052.80)
 .. controls (-571.15,-1064.60) and (-570.44,-1069.62) .. (-565.20,-1074.92)
 .. controls (-559.97,-1080.22) and (-563.48,-1084.91) .. (-536.16,-1090.67)
 .. controls (-508.67,-1096.46) and (-499.74,-1100.01) .. (-498.32,-1099.33)
),
((-570.11,-1257.82)
 .. controls (-568.84,-1253.49) and (-564.15,-1238.29) .. (-559.17,-1230.55)
 .. controls (-554.17,-1222.76) and (-544.05,-1203.74) .. (-541.06,-1198.89)
 .. controls (-538.08,-1194.04) and (-522.07,-1164.20) .. (-520.77,-1161.26)
 .. controls (-519.47,-1158.32) and (-513.96,-1131.47) .. (-508.06,-1111.13)
 .. controls (-502.23,-1091.04) and (-508.84,-1069.04) .. (-509.75,-1066.72)
 .. controls (-510.66,-1064.40) and (-512.29,-1049.40) .. (-511.99,-1046.26)
 .. controls (-511.68,-1043.11) and (-505.53,-1030.68) .. (-504.19,-1026.51)
 .. controls (-502.84,-1022.34) and (-494.71,-1009.90) .. (-490.14,-1005.77)
),
((-660.91,-1257.37)
 .. controls (-659.47,-1260.07) and (-654.79,-1263.84) .. (-652.43,-1265.25)
 .. controls (-650.07,-1266.66) and (-645.70,-1268.56) .. (-643.34,-1268.34)
 .. controls (-640.97,-1268.12) and (-639.69,-1268.99) .. (-634.23,-1265.83)
 .. controls (-628.77,-1262.67) and (-620.24,-1261.47) .. (-618.78,-1257.84)
 .. controls (-617.32,-1254.20) and (-615.06,-1254.69) .. (-614.08,-1254.20)
 .. controls (-612.64,-1253.48) and (-609.68,-1253.86) .. (-607.64,-1255.71)
 .. controls (-606.22,-1257.00) and (-603.25,-1259.93) .. (-602.31,-1261.76)
 .. controls (-600.35,-1265.58) and (-599.46,-1267.39) .. (-595.36,-1267.47)
 .. controls (-591.27,-1267.54) and (-588.25,-1265.45) .. (-584.33,-1263.54)
 .. controls (-580.41,-1261.62) and (-577.55,-1260.57) .. (-575.04,-1259.33)
 .. controls (-572.53,-1258.09) and (-566.96,-1256.47) .. (-566.96,-1256.47)
)));
current_src := "Romeo_entrance.th2 [1169]";
string area_border[];
area_border[1] := "l246-4178-7582";
area_border[2] := "l54-5320-8936";
area_border[3] := "l260-3396-6065";
area_border[4] := "l239-2820-7090";
area_border[5] := "l107-2658-7064";
area_border[6] := "l244-3164-7184";
area_border[7] := "l241-3598-7320";
area_border[8] := "l96-3588-7456";
drawoptions();
a_blocks(buildcycle(((-433.29,-920.05)
 .. controls (-433.29,-920.05) and (-421.16,-940.37) .. (-421.14,-951.15)
 .. controls (-421.11,-961.89) and (-417.77,-979.39) .. (-417.77,-979.39)
),
((-490.14,-1005.77)
 .. controls (-488.04,-1003.16) and (-483.47,-997.22) .. (-478.68,-993.90)
 .. controls (-473.86,-990.56) and (-465.78,-987.89) .. (-461.10,-987.15)
 .. controls (-456.40,-986.41) and (-436.69,-978.70) .. (-433.44,-976.89)
 .. controls (-430.21,-975.09) and (-412.45,-964.77) .. (-407.98,-960.48)
 .. controls (-403.49,-956.19) and (-395.38,-937.10) .. (-392.84,-930.04)
 .. controls (-390.31,-923.00) and (-384.92,-907.71) .. (-383.85,-902.33)
 .. controls (-382.79,-896.96) and (-381.56,-883.51) .. (-380.66,-878.65)
 .. controls (-379.76,-873.79) and (-376.15,-864.77) .. (-373.44,-859.54)
 .. controls (-370.73,-854.31) and (-362.24,-844.36) .. (-355.56,-838.93)
 .. controls (-348.88,-833.50) and (-334.99,-824.45) .. (-331.21,-822.28)
 .. controls (-327.42,-820.11) and (-318.59,-811.81) .. (-315.89,-808.03)
 .. controls (-313.19,-804.25) and (-303.28,-791.64) .. (-299.68,-788.93)
 .. controls (-296.07,-786.23) and (-283.64,-771.45) .. (-279.85,-768.74)
 .. controls (-276.07,-766.04) and (-260.76,-752.52) .. (-252.84,-743.88)
 .. controls (-244.93,-735.25) and (-234.50,-726.27) .. (-228.21,-723.58)
 .. controls (-221.91,-720.89) and (-201.25,-707.27) .. (-197.30,-703.68)
 .. controls (-193.35,-700.10) and (-165.83,-679.08) .. (-159.53,-673.86)
 .. controls (-153.23,-668.64) and (-134.16,-653.88) .. (-127.86,-649.03)
 .. controls (-121.56,-644.17) and (-85.09,-607.21) .. (-80.78,-603.25)
 .. controls (-76.46,-599.30) and (-70.70,-581.48) .. (-67.81,-573.37)
 .. controls (-64.92,-565.26) and (-50.86,-541.81) .. (-48.87,-537.67)
 .. controls (-46.89,-533.53) and (-25.11,-491.77) .. (-21.87,-486.74)
 .. controls (-18.63,-481.70) and (-9.45,-470.36) .. (-6.93,-466.40)
 .. controls (-4.42,-462.44) and (15.90,-432.24) .. (17.34,-425.59)
 .. controls (18.77,-418.94) and (27.41,-401.85) .. (29.03,-396.81)
),
((-570.11,-1257.82)
 .. controls (-568.84,-1253.49) and (-564.15,-1238.29) .. (-559.17,-1230.55)
 .. controls (-554.17,-1222.76) and (-544.05,-1203.74) .. (-541.06,-1198.89)
 .. controls (-538.08,-1194.04) and (-522.07,-1164.20) .. (-520.77,-1161.26)
 .. controls (-519.47,-1158.32) and (-513.96,-1131.47) .. (-508.06,-1111.13)
 .. controls (-502.23,-1091.04) and (-508.84,-1069.04) .. (-509.75,-1066.72)
 .. controls (-510.66,-1064.40) and (-512.29,-1049.40) .. (-511.99,-1046.26)
 .. controls (-511.68,-1043.11) and (-505.53,-1030.68) .. (-504.19,-1026.51)
 .. controls (-502.84,-1022.34) and (-494.71,-1009.90) .. (-490.14,-1005.77)
),
((-687.95,-1035.31)
 .. controls (-687.95,-1035.31) and (-683.70,-1037.85) .. (-677.53,-1037.53)
 .. controls (-671.37,-1037.21) and (-657.91,-1039.77) .. (-650.44,-1038.29)
 .. controls (-642.98,-1036.80) and (-633.37,-1037.88) .. (-626.81,-1040.46)
 .. controls (-620.25,-1043.04) and (-610.92,-1047.97) .. (-603.78,-1045.75)
 .. controls (-596.62,-1043.53) and (-587.36,-1041.03) .. (-579.26,-1052.80)
 .. controls (-571.15,-1064.60) and (-570.44,-1069.62) .. (-565.20,-1074.92)
 .. controls (-559.97,-1080.22) and (-563.48,-1084.91) .. (-536.16,-1090.67)
 .. controls (-508.67,-1096.46) and (-499.74,-1100.01) .. (-498.32,-1099.33)
),
((-616.26,-998.75)
 .. controls (-618.17,-1005.19) and (-635.28,-1015.41) .. (-640.60,-1015.91)
 .. controls (-645.92,-1016.42) and (-665.38,-1016.59) .. (-670.12,-1018.68)
 .. controls (-674.86,-1020.76) and (-687.21,-1043.54) .. (-690.43,-1048.09)
 .. controls (-693.66,-1052.65) and (-699.19,-1059.36) .. (-702.67,-1062.30)
 .. controls (-706.16,-1065.25) and (-719.66,-1075.92) .. (-721.68,-1076.90)
),
((-649.75,-1010.58)
 .. controls (-649.75,-1010.58) and (-629.84,-1019.01) .. (-617.03,-1022.31)
 .. controls (-604.22,-1025.61) and (-580.28,-1033.15) .. (-571.22,-1036.14)
 .. controls (-562.16,-1039.14) and (-553.69,-1046.60) .. (-550.34,-1038.00)
 .. controls (-546.98,-1029.40) and (-544.74,-1016.53) .. (-544.74,-1016.53)
),
((-563.18,-964.48)
 .. controls (-563.18,-964.48) and (-564.39,-983.54) .. (-563.93,-991.67)
 .. controls (-563.48,-999.79) and (-563.41,-1004.01) .. (-559.49,-1009.83)
 .. controls (-555.57,-1015.65) and (-551.67,-1019.70) .. (-547.46,-1021.66)
 .. controls (-543.24,-1023.62) and (-537.64,-1023.53) .. (-535.25,-1019.42)
 .. controls (-532.86,-1015.31) and (-532.24,-1009.36) .. (-527.01,-1007.80)
 .. controls (-521.76,-1006.25) and (-517.92,-1003.57) .. (-511.59,-1002.72)
 .. controls (-505.25,-1001.87) and (-498.17,-1002.41) .. (-495.05,-995.75)
 .. controls (-491.90,-989.06) and (-486.23,-984.88) .. (-483.02,-978.46)
 .. controls (-479.79,-971.99) and (-479.04,-965.46) .. (-479.04,-965.46)
),
((-405.75,-816.74)
 .. controls (-402.87,-816.03) and (-399.30,-824.35) .. (-399.13,-828.69)
 .. controls (-398.97,-833.03) and (-400.44,-846.22) .. (-399.91,-849.29)
 .. controls (-399.37,-852.36) and (-393.43,-865.15) .. (-392.35,-869.46)
 .. controls (-391.27,-873.79) and (-402.40,-890.29) .. (-405.44,-895.48)
 .. controls (-408.49,-900.68) and (-421.43,-916.31) .. (-425.76,-923.35)
 .. controls (-430.09,-930.37) and (-441.74,-937.14) .. (-449.45,-942.14)
 .. controls (-457.19,-947.16) and (-464.79,-957.51) .. (-468.78,-961.14)
 .. controls (-472.76,-964.77) and (-487.82,-973.88) .. (-492.63,-975.95)
 .. controls (-497.42,-978.01) and (-523.54,-982.27) .. (-539.33,-986.42)
 .. controls (-555.03,-990.55) and (-555.27,-985.91) .. (-558.09,-984.01)
 .. controls (-560.91,-982.11) and (-563.79,-974.02) .. (-564.70,-970.80)
)));
current_src := "Romeo_entrance.th2 [1152]";
string area_border[];
area_border[1] := "l249-4050-7530";
area_border[2] := "l54-5320-8936";
area_border[3] := "l248-3948-7524";
area_border[4] := "l96-3588-7456";
drawoptions();
a_debris(buildcycle(((-462.39,-944.44)
 -- (-432.88,-986.57)
),
((-490.14,-1005.77)
 .. controls (-488.04,-1003.16) and (-483.47,-997.22) .. (-478.68,-993.90)
 .. controls (-473.86,-990.56) and (-465.78,-987.89) .. (-461.10,-987.15)
 .. controls (-456.40,-986.41) and (-436.69,-978.70) .. (-433.44,-976.89)
 .. controls (-430.21,-975.09) and (-412.45,-964.77) .. (-407.98,-960.48)
 .. controls (-403.49,-956.19) and (-395.38,-937.10) .. (-392.84,-930.04)
 .. controls (-390.31,-923.00) and (-384.92,-907.71) .. (-383.85,-902.33)
 .. controls (-382.79,-896.96) and (-381.56,-883.51) .. (-380.66,-878.65)
 .. controls (-379.76,-873.79) and (-376.15,-864.77) .. (-373.44,-859.54)
 .. controls (-370.73,-854.31) and (-362.24,-844.36) .. (-355.56,-838.93)
 .. controls (-348.88,-833.50) and (-334.99,-824.45) .. (-331.21,-822.28)
 .. controls (-327.42,-820.11) and (-318.59,-811.81) .. (-315.89,-808.03)
 .. controls (-313.19,-804.25) and (-303.28,-791.64) .. (-299.68,-788.93)
 .. controls (-296.07,-786.23) and (-283.64,-771.45) .. (-279.85,-768.74)
 .. controls (-276.07,-766.04) and (-260.76,-752.52) .. (-252.84,-743.88)
 .. controls (-244.93,-735.25) and (-234.50,-726.27) .. (-228.21,-723.58)
 .. controls (-221.91,-720.89) and (-201.25,-707.27) .. (-197.30,-703.68)
 .. controls (-193.35,-700.10) and (-165.83,-679.08) .. (-159.53,-673.86)
 .. controls (-153.23,-668.64) and (-134.16,-653.88) .. (-127.86,-649.03)
 .. controls (-121.56,-644.17) and (-85.09,-607.21) .. (-80.78,-603.25)
 .. controls (-76.46,-599.30) and (-70.70,-581.48) .. (-67.81,-573.37)
 .. controls (-64.92,-565.26) and (-50.86,-541.81) .. (-48.87,-537.67)
 .. controls (-46.89,-533.53) and (-25.11,-491.77) .. (-21.87,-486.74)
 .. controls (-18.63,-481.70) and (-9.45,-470.36) .. (-6.93,-466.40)
 .. controls (-4.42,-462.44) and (15.90,-432.24) .. (17.34,-425.59)
 .. controls (18.77,-418.94) and (27.41,-401.85) .. (29.03,-396.81)
),
((-467.09,-950.96)
 -- (-457.80,-994.63)
),
((-405.75,-816.74)
 .. controls (-402.87,-816.03) and (-399.30,-824.35) .. (-399.13,-828.69)
 .. controls (-398.97,-833.03) and (-400.44,-846.22) .. (-399.91,-849.29)
 .. controls (-399.37,-852.36) and (-393.43,-865.15) .. (-392.35,-869.46)
 .. controls (-391.27,-873.79) and (-402.40,-890.29) .. (-405.44,-895.48)
 .. controls (-408.49,-900.68) and (-421.43,-916.31) .. (-425.76,-923.35)
 .. controls (-430.09,-930.37) and (-441.74,-937.14) .. (-449.45,-942.14)
 .. controls (-457.19,-947.16) and (-464.79,-957.51) .. (-468.78,-961.14)
 .. controls (-472.76,-964.77) and (-487.82,-973.88) .. (-492.63,-975.95)
 .. controls (-497.42,-978.01) and (-523.54,-982.27) .. (-539.33,-986.42)
 .. controls (-555.03,-990.55) and (-555.27,-985.91) .. (-558.09,-984.01)
 .. controls (-560.91,-982.11) and (-563.79,-974.02) .. (-564.70,-970.80)
)));
current_src := "Romeo_entrance.th2 [1126]";
string area_border[];
area_border[1] := "l688-3876-8270";
drawoptions();
a_debris(buildcycle(((-541.98,-827.09)
 -- (-513.04,-870.28)
 -- (-473.72,-836.16)
 -- (-511.27,-798.68)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1025]";
string area_border[];
area_border[1] := "l611-4190-8982";
area_border[2] := "l252-4140-8522";
area_border[3] := "l609-4168-8172";
area_border[4] := "l620-4610-8624";
area_border[5] := "l610-4496-8810";
area_border[6] := "l614-4454-8846";
drawoptions();
a_water(buildcycle(((-377.89,-725.01)
 .. controls (-377.89,-725.01) and (-391.10,-699.29) .. (-409.78,-703.89)
 .. controls (-428.44,-708.49) and (-574.22,-884.61) .. (-574.22,-884.61)
),
((-574.22,-884.61)
 .. controls (-574.22,-884.61) and (-576.25,-904.56) .. (-542.56,-919.38)
 .. controls (-535.96,-922.28) and (-527.11,-916.08) .. (-521.96,-913.34)
 .. controls (-504.84,-904.25) and (-495.55,-896.07) .. (-495.55,-896.07)
),
((-495.55,-896.07)
 -- (-433.29,-920.05)
 .. controls (-433.29,-920.05) and (-437.26,-971.55) .. (-418.82,-986.53)
 .. controls (-400.37,-1001.51) and (-298.58,-799.00) .. (-298.58,-799.00)
 .. controls (-298.58,-799.00) and (-311.37,-789.94) .. (-318.82,-767.80)
 .. controls (-321.72,-759.19) and (-336.53,-756.02) .. (-341.94,-761.08)
),
((-361.76,-746.00)
 .. controls (-361.76,-746.00) and (-381.14,-773.98) .. (-364.56,-789.07)
 .. controls (-347.98,-804.15) and (-339.04,-767.89) .. (-341.94,-761.08)
),
((-361.76,-746.00)
 -- (-364.26,-735.53)
),
((-377.89,-725.01)
 .. controls (-377.89,-725.01) and (-378.74,-735.71) .. (-364.26,-735.53)
)));
ATTR__id := "l183-9896-18512";
ATTR__height := -1;
drawoptions();
l_border_invisible(((498.30,776.98)
 .. controls (501.35,779.50) and (512.33,786.33) .. (516.47,793.35)
 .. controls (520.61,800.37) and (522.77,814.05) .. (525.65,822.51)
 .. controls (528.53,830.97) and (531.95,831.51) .. (538.62,834.93)
 .. controls (545.28,838.35) and (561.48,852.39) .. (565.80,856.00)
 .. controls (570.12,859.60) and (588.84,882.46) .. (592.80,888.57)
 .. controls (596.76,894.69) and (610.08,918.63) .. (612.42,930.33)
 .. controls (614.76,942.03) and (613.14,987.93) .. (612.06,992.25)
 .. controls (610.98,996.57) and (607.74,1010.43) .. (606.12,1022.67)
 .. controls (604.50,1034.91) and (597.12,1060.29) .. (594.06,1066.23)
 .. controls (591.00,1072.17) and (581.64,1080.09) .. (574.07,1082.43)
 .. controls (566.51,1084.77) and (553.73,1070.55) .. (550.68,1067.31)
 .. controls (547.62,1064.07) and (538.44,1050.39) .. (536.46,1045.71)
 .. controls (534.48,1041.03) and (521.88,1032.21) .. (520.44,1030.95)
));
ATTR__id := "l607-9326-19350";
ATTR__height := -1;
drawoptions();
l_border_invisible(((515.58,1191.51)
 -- (520.44,1030.95)
));
ATTR__id := "l608-9224-17162";
ATTR__height := -1;
drawoptions();
l_border_invisible(((498.30,776.98)
 .. controls (498.30,776.98) and (302.11,539.57) .. (328.38,502.84)
));
ATTR__id := "l609-8620-15342";
ATTR__height := -1;
drawoptions();
l_border_invisible(((355.03,387.64)
 -- (412.97,505.52)
));
ATTR__id := "l610-10188-18254";
ATTR__height := -1;
drawoptions();
l_border_invisible(((650.22,875.44)
 -- (669.67,1016.56)
 -- (721.15,1179.29)
 -- (554.45,1268.54)
));
ATTR__id := "l688-9440-19696";
ATTR__height := -1;
drawoptions();
l_border_invisible(((515.58,1191.51)
 -- (554.45,1268.54)
));
ATTR__id := "l189-8350-14756";
ATTR__height := -1;
drawoptions();
l_border_invisible(((289.86,386.55)
 .. controls (289.86,386.55) and (297.06,353.08) .. (295.98,342.99)
 .. controls (294.90,332.91) and (290.93,310.95) .. (291.30,304.47)
 .. controls (291.66,297.99) and (286.26,291.16) .. (296.70,294.76)
 .. controls (307.14,298.36) and (318.66,312.40) .. (321.54,317.44)
 .. controls (324.42,322.48) and (332.34,332.92) .. (337.03,340.12)
 .. controls (341.71,347.32) and (352.51,354.53) .. (352.51,354.53)
));
ATTR__id := "l191-7944-14488";
ATTR__height := -1;
drawoptions();
l_border_invisible(((199.51,256.62)
 .. controls (205.27,260.57) and (231.91,270.65) .. (236.23,272.09)
 .. controls (240.55,273.53) and (270.42,286.48) .. (275.10,288.64)
 .. controls (279.78,290.80) and (293.46,295.48) .. (293.46,295.48)
));
ATTR__id := "l192-7526-13736";
ATTR__height := -1;
drawoptions();
l_border_invisible(((12.30,-65.23)
 .. controls (14.46,-65.23) and (51.90,-51.20) .. (63.07,-40.76)
 .. controls (74.23,-30.31) and (93.67,-15.91) .. (103.75,-9.43)
 .. controls (113.83,-2.95) and (122.47,-1.15) .. (128.22,1.37)
 .. controls (133.98,3.88) and (143.34,25.85) .. (143.71,32.69)
 .. controls (144.07,39.53) and (148.03,58.26) .. (151.63,70.50)
 .. controls (155.23,82.73) and (159.19,94.25) .. (162.06,102.89)
 .. controls (164.94,111.52) and (172.50,129.52) .. (176.46,136.73)
 .. controls (180.43,143.93) and (194.11,173.45) .. (195.91,183.53)
 .. controls (197.71,193.61) and (193.03,217.73) .. (191.59,223.85)
 .. controls (190.15,229.97) and (185.84,244.74) .. (184.76,246.90)
));
ATTR__id := "l194-6756-12360";
ATTR__height := -1;
drawoptions();
l_border_invisible(((93.32,-74.22)
 .. controls (91.52,-74.94) and (74.95,-76.39) .. (71.35,-81.07)
 .. controls (67.75,-85.75) and (63.07,-88.99) .. (54.43,-94.03)
 .. controls (45.79,-99.07) and (41.10,-100.51) .. (37.15,-106.99)
 .. controls (33.19,-113.47) and (32.47,-120.30) .. (32.83,-126.78)
 .. controls (33.19,-133.26) and (29.23,-137.94) .. (29.23,-143.34)
 .. controls (29.23,-148.74) and (29.95,-150.90) .. (31.39,-153.42)
 .. controls (32.83,-155.94) and (42.19,-164.94) .. (42.19,-164.94)
));
ATTR__id := "l195-6512-12060";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-17.22,-122.47)
 .. controls (-17.22,-126.43) and (-17.58,-140.12) .. (-16.14,-142.64)
 .. controls (-14.70,-145.16) and (-16.51,-152.37) .. (-10.38,-154.16)
 .. controls (-4.26,-155.96) and (9.78,-157.03) .. (14.46,-155.59)
 .. controls (19.15,-154.15) and (23.83,-151.27) .. (25.99,-151.26)
 .. controls (28.15,-151.26) and (33.91,-150.18) .. (33.91,-150.18)
));
ATTR__id := "l196-6316-11828";
ATTR__height := -1;
drawoptions();
l_flowstone(((-98.53,-328.31)
 .. controls (-98.53,-328.31) and (-89.54,-328.32) .. (-83.06,-327.60)
 .. controls (-76.59,-326.89) and (-64.72,-325.46) .. (-60.76,-324.39)
 .. controls (-56.80,-323.31) and (-39.18,-313.98) .. (-32.34,-309.31)
 .. controls (-25.51,-304.64) and (-17.24,-293.48) .. (-16.51,-285.20)
 .. controls (-15.79,-276.91) and (-15.07,-268.99) .. (-13.62,-258.18)
 .. controls (-12.18,-247.38) and (-12.54,-231.90) .. (-14.34,-222.90)
 .. controls (-16.14,-213.90) and (-23.33,-204.90) .. (-28.01,-202.38)
 .. controls (-32.69,-199.86) and (-47.81,-188.70) .. (-47.81,-188.70)
));
ATTR__id := "l197-6472-11896";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-27.29,-209.21)
 .. controls (-21.89,-204.90) and (-21.89,-197.34) .. (-18.66,-193.74)
 .. controls (-15.42,-190.15) and (-2.82,-183.67) .. (1.50,-180.43)
 .. controls (5.82,-177.19) and (5.10,-173.95) .. (11.94,-173.23)
 .. controls (18.78,-172.51) and (38.22,-177.19) .. (40.74,-179.71)
));
ATTR__id := "l200-6296-10916";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-40.98,-308.22)
 .. controls (-40.98,-308.22) and (-38.10,-322.97) .. (-38.81,-336.65)
 .. controls (-39.52,-350.32) and (-41.32,-374.79) .. (-38.44,-382.35)
 .. controls (-35.56,-389.91) and (-30.88,-388.11) .. (-34.84,-396.39)
 .. controls (-38.80,-404.67) and (-59.33,-425.92) .. (-65.82,-439.62)
 .. controls (-72.32,-453.32) and (-75.92,-469.88) .. (-75.92,-478.87)
 .. controls (-75.91,-487.86) and (-91.72,-531.01) .. (-97.48,-538.58)
 .. controls (-103.24,-546.14) and (-106.86,-562.00) .. (-109.74,-573.89)
 .. controls (-112.62,-585.76) and (-112.97,-603.39) .. (-118.72,-606.62)
 .. controls (-124.47,-609.84) and (-128.43,-610.91) .. (-137.42,-610.55)
 .. controls (-146.42,-610.18) and (-154.34,-612.70) .. (-165.51,-618.48)
 .. controls (-176.69,-624.27) and (-191.83,-625.75) .. (-198.32,-629.72)
 .. controls (-204.80,-633.69) and (-206.25,-633.32) .. (-208.76,-643.76)
 .. controls (-211.27,-654.18) and (-213.78,-659.21) .. (-213.40,-668.54)
 .. controls (-213.02,-677.86) and (-221.65,-680.00) .. (-212.28,-685.39)
 .. controls (-202.91,-690.78) and (-198.22,-694.00) .. (-192.10,-692.21)
 .. controls (-185.99,-690.41) and (-171.93,-693.98) .. (-171.93,-693.98)
));
ATTR__id := "l201-4832-9212";
ATTR__height := -1;
drawoptions();
l_flowstone(((-381.30,-660.99)
 .. controls (-381.30,-660.99) and (-368.03,-673.31) .. (-359.04,-676.57)
 .. controls (-350.06,-679.83) and (-325.94,-676.94) .. (-315.49,-673.70)
 .. controls (-305.06,-670.46) and (-261.57,-648.63) .. (-252.96,-643.27)
 .. controls (-244.34,-637.91) and (-223.15,-630.78) .. (-213.79,-621.78)
 .. controls (-203.86,-612.23) and (-199.72,-602.66) .. (-193.94,-590.38)
 .. controls (-192.01,-586.29) and (-191.42,-578.25) .. (-197.15,-573.06)
 .. controls (-207.94,-563.32) and (-214.42,-564.03) .. (-221.60,-560.06)
 .. controls (-228.79,-556.08) and (-246.04,-544.51) .. (-246.04,-544.51)
));
ATTR__id := "l624-5116-9242";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-392.90,-699.27)
 -- (-377.48,-709.81)
 -- (-350.12,-701.88)
 -- (-343.34,-725.39)
 -- (-294.64,-772.74)
 -- (-268.69,-752.53)
 -- (-220.49,-710.49)
 -- (-226.69,-677.84)
 -- (-251.87,-660.89)
 -- (-270.19,-659.39)
 -- (-301.10,-674.43)
 -- (-343.22,-682.36)
 -- (-373.43,-675.46)
 -- cycle
));
ATTR__id := "l627-5152-9338";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-383.55,-697.49)
 .. controls (-383.55,-697.49) and (-385.66,-679.79) .. (-363.38,-682.71)
 .. controls (-341.07,-685.63) and (-330.28,-688.85) .. (-314.42,-681.64)
 .. controls (-298.58,-674.43) and (-271.26,-660.46) .. (-260.13,-654.75)
 .. controls (-249.01,-649.04) and (-241.83,-638.29) .. (-223.87,-636.90)
 .. controls (-205.88,-635.50) and (-212.01,-640.16) .. (-217.74,-657.76)
 .. controls (-223.46,-675.33) and (-221.28,-682.15) .. (-217.31,-689.69)
 .. controls (-213.33,-697.22) and (-206.13,-696.15) .. (-203.60,-702.96)
 .. controls (-201.06,-709.78) and (-203.52,-742.79) .. (-212.14,-750.33)
 .. controls (-220.78,-757.88) and (-280.92,-794.64) .. (-280.92,-794.64)
 .. controls (-280.92,-794.64) and (-321.73,-764.59) .. (-328.22,-749.50)
 .. controls (-334.72,-734.40) and (-343.68,-715.26) .. (-350.86,-708.40)
 .. controls (-358.04,-701.52) and (-371.73,-708.74) .. (-378.18,-703.66)
 .. controls (-384.63,-698.58) and (-383.55,-697.49) .. cycle
));
ATTR__id := "l630-6180-10998";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-166.56,-567.67)
 .. controls (-166.56,-567.67) and (-181.24,-581.41) .. (-181.69,-582.08)
 .. controls (-194.32,-601.21) and (-205.86,-607.72) .. (-193.26,-616.73)
 .. controls (-180.67,-625.73) and (-140.66,-605.14) .. (-136.34,-603.71)
 .. controls (-132.03,-602.28) and (-115.49,-582.52) .. (-108.64,-547.21)
 .. controls (-101.80,-511.93) and (-73.04,-465.20) .. (-71.59,-447.19)
 .. controls (-70.14,-429.16) and (-43.11,-398.54) .. (-49.95,-380.54)
 .. controls (-56.79,-362.54) and (-51.76,-344.91) .. (-71.19,-342.73)
 .. controls (-90.62,-340.55) and (-84.86,-341.28) .. (-95.65,-362.50)
 .. controls (-106.45,-383.74) and (-121.57,-396.69) .. (-126.25,-404.97)
 .. controls (-130.93,-413.25) and (-167.63,-506.80) .. (-167.63,-506.80)
 .. controls (-167.63,-506.80) and (-161.51,-508.25) .. (-159.36,-541.74)
 .. controls (-158.98,-547.54) and (-162.60,-560.11) .. (-162.60,-560.11)
 -- cycle
));
ATTR__id := "l184-9852-17572";
ATTR__height := -1;
drawoptions();
l_border_invisible(((650.22,875.44)
 .. controls (648.06,873.10) and (627.90,857.62) .. (621.60,852.22)
 .. controls (615.30,846.82) and (595.68,837.28) .. (592.08,830.44)
 .. controls (588.48,823.60) and (582.18,814.96) .. (579.84,808.48)
 .. controls (577.50,802.00) and (579.11,791.02) .. (578.03,785.79)
 .. controls (576.95,780.57) and (577.13,773.19) .. (573.35,762.39)
 .. controls (569.57,751.59) and (561.65,738.45) .. (559.85,731.07)
 .. controls (558.05,723.69) and (549.77,716.13) .. (546.89,708.93)
 .. controls (544.01,701.73) and (534.65,688.77) .. (531.59,685.17)
 .. controls (528.53,681.57) and (502.80,655.30) .. (499.20,648.46)
 .. controls (495.60,641.62) and (474.72,613.91) .. (470.58,608.68)
 .. controls (466.44,603.46) and (458.34,587.62) .. (455.46,580.78)
 .. controls (452.58,573.94) and (451.32,571.41) .. (445.74,566.55)
 .. controls (440.16,561.69) and (434.22,554.85) .. (429.36,548.73)
 .. controls (424.50,542.61) and (417.12,530.91) .. (416.22,526.05)
 .. controls (415.31,521.19) and (413.51,510.21) .. (412.97,505.52)
));
ATTR__id := "l187-8364-15472";
ATTR__height := -1;
drawoptions();
l_border_invisible(((328.38,502.84)
 .. controls (329.46,498.88) and (333.42,487.72) .. (333.42,476.56)
 .. controls (333.42,465.40) and (329.46,454.59) .. (331.62,446.31)
 .. controls (333.78,438.03) and (331.26,428.67) .. (333.78,420.03)
 .. controls (336.30,411.39) and (334.50,402.75) .. (338.46,398.79)
 .. controls (342.42,394.83) and (351.79,390.88) .. (355.03,387.64)
));
ATTR__id := "l239-2820-7090";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-687.95,-1035.31)
 .. controls (-687.95,-1035.31) and (-683.70,-1037.85) .. (-677.53,-1037.53)
 .. controls (-671.37,-1037.21) and (-657.91,-1039.77) .. (-650.44,-1038.29)
 .. controls (-642.98,-1036.80) and (-633.37,-1037.88) .. (-626.81,-1040.46)
 .. controls (-620.25,-1043.04) and (-610.92,-1047.97) .. (-603.78,-1045.75)
 .. controls (-596.62,-1043.53) and (-587.36,-1041.03) .. (-579.26,-1052.80)
 .. controls (-571.15,-1064.60) and (-570.44,-1069.62) .. (-565.20,-1074.92)
 .. controls (-559.97,-1080.22) and (-563.48,-1084.91) .. (-536.16,-1090.67)
 .. controls (-508.67,-1096.46) and (-499.74,-1100.01) .. (-498.32,-1099.33)
));
ATTR__id := "l240-2678-6802";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-692.78,-1042.10)
 .. controls (-692.78,-1042.10) and (-689.47,-1066.67) .. (-686.93,-1073.60)
 .. controls (-684.44,-1080.42) and (-677.69,-1091.75) .. (-672.95,-1096.38)
 .. controls (-668.13,-1101.10) and (-656.88,-1112.96) .. (-654.92,-1114.41)
));
ATTR__id := "l241-3598-7320";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-563.18,-964.48)
 .. controls (-563.18,-964.48) and (-564.39,-983.54) .. (-563.93,-991.67)
 .. controls (-563.48,-999.79) and (-563.41,-1004.01) .. (-559.49,-1009.83)
 .. controls (-555.57,-1015.65) and (-551.67,-1019.70) .. (-547.46,-1021.66)
 .. controls (-543.24,-1023.62) and (-537.64,-1023.53) .. (-535.25,-1019.42)
 .. controls (-532.86,-1015.31) and (-532.24,-1009.36) .. (-527.01,-1007.80)
 .. controls (-521.76,-1006.25) and (-517.92,-1003.57) .. (-511.59,-1002.72)
 .. controls (-505.25,-1001.87) and (-498.17,-1002.41) .. (-495.05,-995.75)
 .. controls (-491.90,-989.06) and (-486.23,-984.88) .. (-483.02,-978.46)
 .. controls (-479.79,-971.99) and (-479.04,-965.46) .. (-479.04,-965.46)
));
ATTR__id := "l244-3164-7184";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-649.75,-1010.58)
 .. controls (-649.75,-1010.58) and (-629.84,-1019.01) .. (-617.03,-1022.31)
 .. controls (-604.22,-1025.61) and (-580.28,-1033.15) .. (-571.22,-1036.14)
 .. controls (-562.16,-1039.14) and (-553.69,-1046.60) .. (-550.34,-1038.00)
 .. controls (-546.98,-1029.40) and (-544.74,-1016.53) .. (-544.74,-1016.53)
));
ATTR__id := "l245-3602-6960";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-569.34,-1078.94)
 .. controls (-569.34,-1078.94) and (-544.98,-1077.79) .. (-537.29,-1075.99)
 .. controls (-529.58,-1074.19) and (-503.98,-1061.95) .. (-503.98,-1061.95)
));
ATTR__id := "l246-4178-7582";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-433.29,-920.05)
 .. controls (-433.29,-920.05) and (-421.16,-940.37) .. (-421.14,-951.15)
 .. controls (-421.11,-961.89) and (-417.77,-979.39) .. (-417.77,-979.39)
));
ATTR__id := "l248-3948-7524";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-467.09,-950.96)
 -- (-457.80,-994.63)
));
ATTR__id := "l249-4050-7530";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-462.39,-944.44)
 -- (-432.88,-986.57)
));
ATTR__id := "l251-4424-8196";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-404.92,-842.78)
 .. controls (-401.34,-845.68) and (-365.68,-853.21) .. (-360.99,-851.39)
));
ATTR__id := "l252-4140-8522";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-574.22,-884.61)
 .. controls (-574.22,-884.61) and (-576.25,-904.56) .. (-542.56,-919.38)
 .. controls (-535.96,-922.28) and (-527.11,-916.08) .. (-521.96,-913.34)
 .. controls (-504.84,-904.25) and (-495.55,-896.07) .. (-495.55,-896.07)
));
ATTR__id := "l688-3876-8270";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-541.98,-827.09)
 -- (-513.04,-870.28)
 -- (-473.72,-836.16)
 -- (-511.27,-798.68)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-364.26,-735.53)
 .. controls (-340.84,-735.14) and (-350.17,-718.89) .. (-353.04,-714.55)
 .. controls (-355.00,-711.59) and (-356.61,-706.23) .. (-365.62,-708.75)
 .. controls (-379.92,-712.76) and (-377.89,-725.01) .. (-377.89,-725.01)
));
ATTR__id := "l620-4610-8624";
ATTR__height := -1;
drawoptions();
l_rockborder(((-361.76,-746.00)
 .. controls (-361.76,-746.00) and (-381.14,-773.98) .. (-364.56,-789.07)
 .. controls (-347.98,-804.15) and (-339.04,-767.89) .. (-341.94,-761.08)
));
ATTR__id := "l614-4454-8846";
ATTR__height := -1;
drawoptions();
l_rockborder(((-377.89,-725.01)
 .. controls (-377.89,-725.01) and (-378.74,-735.71) .. (-364.26,-735.53)
));
ATTR__id := "l609-4168-8172";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-495.55,-896.07)
 -- (-433.29,-920.05)
 .. controls (-433.29,-920.05) and (-437.26,-971.55) .. (-418.82,-986.53)
 .. controls (-400.37,-1001.51) and (-298.58,-799.00) .. (-298.58,-799.00)
 .. controls (-298.58,-799.00) and (-311.37,-789.94) .. (-318.82,-767.80)
 .. controls (-321.72,-759.19) and (-336.53,-756.02) .. (-341.94,-761.08)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-341.94,-761.08)
 .. controls (-341.94,-761.08) and (-344.09,-735.15) .. (-361.76,-746.00)
));
ATTR__id := "l610-4496-8810";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-361.76,-746.00)
 -- (-364.26,-735.53)
));
ATTR__id := "l611-4190-8982";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-377.89,-725.01)
 .. controls (-377.89,-725.01) and (-391.10,-699.29) .. (-409.78,-703.89)
 .. controls (-428.44,-708.49) and (-574.22,-884.61) .. (-574.22,-884.61)
));
endfig;
beginfig(6);
draw_upscrap(1)(1,((29.03,-396.81)
 .. controls (33.17,-388.16) and (25.98,-371.59) .. (33.91,-351.41)
 .. controls (41.83,-331.25) and (51.91,-313.25) .. (48.30,-291.66)
 .. controls (44.70,-270.06) and (41.81,-243.43) .. (38.21,-232.64)
 .. controls (34.60,-221.85) and (35.33,-199.52) .. (36.06,-186.55)
 .. controls (36.78,-173.59) and (35.35,-149.82) .. (46.87,-132.54)
 .. controls (58.39,-115.26) and (72.07,-80.71) .. (92.23,-64.86)
 .. controls (112.39,-49.02) and (153.42,-6.56) .. (160.62,6.40)
 .. controls (167.82,19.37) and (204.56,52.51) .. (210.32,65.47)
 .. controls (216.08,78.43) and (239.12,122.34) .. (242.71,133.86)
 .. controls (246.31,145.37) and (252.78,214.47) .. (294.55,245.45)
 .. controls (336.31,276.42) and (336.31,313.85) .. (342.07,323.93)
 .. controls (347.83,334.01) and (350.71,386.56) .. (350.70,390.88)
 .. controls (350.70,395.20) and (352.86,418.96) .. (361.50,434.08)
 .. controls (370.14,449.20) and (385.26,470.07) .. (392.45,480.87)
 .. controls (399.65,491.66) and (416.21,523.35) .. (421.98,529.83)
 .. controls (427.74,536.31) and (454.38,554.31) .. (463.02,564.40)
 .. controls (471.66,574.48) and (545.10,654.40) .. (551.57,666.64)
 .. controls (558.05,678.87) and (563.81,701.91) .. (568.13,713.43)
 .. controls (572.45,724.95) and (583.97,735.03) .. (590.45,744.40)
 .. controls (596.93,753.76) and (617.82,779.68) .. (617.82,790.48)
 .. controls (617.82,801.28) and (626.46,830.80) .. (636.54,847.36)
 .. controls (646.62,863.92) and (650.94,902.80) .. (650.94,908.56)
 .. controls (650.94,914.32) and (656.71,962.56) .. (654.55,974.79)
 .. controls (652.38,987.03) and (644.46,1010.07) .. (653.11,1029.52)
 .. controls (661.75,1048.96) and (676.87,1077.76) .. (683.35,1089.28)
 .. controls (689.83,1100.80) and (705.67,1128.17) .. (704.23,1140.41)
 .. controls (702.79,1152.65) and (700.81,1174.79) .. (674.88,1181.98)
 .. controls (648.96,1189.18) and (612.78,1192.96) .. (600.54,1192.23)
 .. controls (588.30,1191.51) and (559.50,1186.47) .. (544.38,1205.19)
 .. controls (529.26,1223.90) and (532.86,1215.27) .. (530.70,1221.03)
),
1,((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
),
1,((-99.61,-340.90)
 .. controls (-101.41,-347.38) and (-108.97,-370.59) .. (-108.97,-376.35)
 .. controls (-108.97,-382.11) and (-115.47,-416.15) .. (-117.63,-422.28)
 .. controls (-119.79,-428.40) and (-124.83,-435.60) .. (-126.99,-440.82)
 .. controls (-129.15,-446.04) and (-143.90,-478.59) .. (-146.41,-485.42)
 .. controls (-148.93,-492.26) and (-159.89,-518.88) .. (-162.05,-522.29)
 .. controls (-164.21,-525.71) and (-180.40,-532.17) .. (-191.01,-534.86)
 .. controls (-201.62,-537.55) and (-229.68,-546.16) .. (-237.96,-548.49)
 .. controls (-246.23,-550.82) and (-288.66,-573.61) .. (-297.11,-580.25)
 .. controls (-305.56,-586.90) and (-335.59,-614.02) .. (-340.26,-620.86)
 .. controls (-344.94,-627.69) and (-378.97,-663.53) .. (-382.77,-673.45)
 .. controls (-386.57,-683.38) and (-397.02,-697.99) .. (-400.27,-703.03)
 .. controls (-403.51,-708.08) and (-416.81,-719.92) .. (-420.95,-731.98)
 .. controls (-425.08,-744.03) and (-440.69,-771.32) .. (-446.97,-777.95)
 .. controls (-453.25,-784.58) and (-466.87,-786.82) .. (-471.35,-787.33)
 .. controls (-475.83,-787.84) and (-489.97,-791.50) .. (-503.58,-807.58)
 .. controls (-517.16,-823.63) and (-524.48,-831.64) .. (-529.29,-838.77)
 .. controls (-534.11,-845.89) and (-539.63,-847.96) .. (-551.89,-865.71)
 .. controls (-564.11,-883.40) and (-570.65,-890.41) .. (-572.56,-899.83)
 .. controls (-574.46,-909.25) and (-584.88,-932.95) .. (-588.16,-939.75)
 .. controls (-591.42,-946.52) and (-598.80,-958.02) .. (-603.58,-965.17)
 .. controls (-608.34,-972.28) and (-611.67,-979.78) .. (-613.27,-986.12)
 .. controls (-614.86,-992.44) and (-616.40,-999.95) .. (-616.40,-999.95)
),
1,((-616.26,-998.75)
 .. controls (-618.17,-1005.19) and (-635.28,-1015.41) .. (-640.60,-1015.91)
 .. controls (-645.92,-1016.42) and (-665.38,-1016.59) .. (-670.12,-1018.68)
 .. controls (-674.86,-1020.76) and (-687.21,-1043.54) .. (-690.43,-1048.09)
 .. controls (-693.66,-1052.65) and (-699.19,-1059.36) .. (-702.67,-1062.30)
 .. controls (-706.16,-1065.25) and (-719.66,-1075.92) .. (-721.68,-1076.90)
),
1,((-677.94,-1112.80)
 .. controls (-675.27,-1110.71) and (-669.69,-1108.80) .. (-663.39,-1108.57)
 .. controls (-657.23,-1108.34) and (-658.20,-1110.22) .. (-649.67,-1108.22)
 .. controls (-641.19,-1106.24) and (-644.11,-1109.62) .. (-643.01,-1112.56)
 .. controls (-641.89,-1115.53) and (-643.33,-1121.83) .. (-643.59,-1127.42)
 .. controls (-643.86,-1133.17) and (-646.64,-1151.99) .. (-647.10,-1155.16)
 .. controls (-647.56,-1158.35) and (-656.18,-1206.80) .. (-658.25,-1218.58)
 .. controls (-660.27,-1230.04) and (-658.75,-1257.37) .. (-657.67,-1261.87)
),
1,((-657.67,-1261.87)
 -- (-657.67,-1261.87)),
1,((-660.91,-1257.37)
 .. controls (-659.47,-1260.07) and (-654.79,-1263.84) .. (-652.43,-1265.25)
 .. controls (-650.07,-1266.66) and (-645.70,-1268.56) .. (-643.34,-1268.34)
 .. controls (-640.97,-1268.12) and (-639.69,-1268.99) .. (-634.23,-1265.83)
 .. controls (-628.77,-1262.67) and (-620.24,-1261.47) .. (-618.78,-1257.84)
 .. controls (-617.32,-1254.20) and (-615.06,-1254.69) .. (-614.08,-1254.20)
 .. controls (-612.64,-1253.48) and (-609.68,-1253.86) .. (-607.64,-1255.71)
 .. controls (-606.22,-1257.00) and (-603.25,-1259.93) .. (-602.31,-1261.76)
 .. controls (-600.35,-1265.58) and (-599.46,-1267.39) .. (-595.36,-1267.47)
 .. controls (-591.27,-1267.54) and (-588.25,-1265.45) .. (-584.33,-1263.54)
 .. controls (-580.41,-1261.62) and (-577.55,-1260.57) .. (-575.04,-1259.33)
 .. controls (-572.53,-1258.09) and (-566.96,-1256.47) .. (-566.96,-1256.47)
),
1,((-570.11,-1257.82)
 .. controls (-568.84,-1253.49) and (-564.15,-1238.29) .. (-559.17,-1230.55)
 .. controls (-554.17,-1222.76) and (-544.05,-1203.74) .. (-541.06,-1198.89)
 .. controls (-538.08,-1194.04) and (-522.07,-1164.20) .. (-520.77,-1161.26)
 .. controls (-519.47,-1158.32) and (-513.96,-1131.47) .. (-508.06,-1111.13)
 .. controls (-502.23,-1091.04) and (-508.84,-1069.04) .. (-509.75,-1066.72)
 .. controls (-510.66,-1064.40) and (-512.29,-1049.40) .. (-511.99,-1046.26)
 .. controls (-511.68,-1043.11) and (-505.53,-1030.68) .. (-504.19,-1026.51)
 .. controls (-502.84,-1022.34) and (-494.71,-1009.90) .. (-490.14,-1005.77)
),
1,((-490.14,-1005.77)
 .. controls (-488.04,-1003.16) and (-483.47,-997.22) .. (-478.68,-993.90)
 .. controls (-473.86,-990.56) and (-465.78,-987.89) .. (-461.10,-987.15)
 .. controls (-456.40,-986.41) and (-436.69,-978.70) .. (-433.44,-976.89)
 .. controls (-430.21,-975.09) and (-412.45,-964.77) .. (-407.98,-960.48)
 .. controls (-403.49,-956.19) and (-395.38,-937.10) .. (-392.84,-930.04)
 .. controls (-390.31,-923.00) and (-384.92,-907.71) .. (-383.85,-902.33)
 .. controls (-382.79,-896.96) and (-381.56,-883.51) .. (-380.66,-878.65)
 .. controls (-379.76,-873.79) and (-376.15,-864.77) .. (-373.44,-859.54)
 .. controls (-370.73,-854.31) and (-362.24,-844.36) .. (-355.56,-838.93)
 .. controls (-348.88,-833.50) and (-334.99,-824.45) .. (-331.21,-822.28)
 .. controls (-327.42,-820.11) and (-318.59,-811.81) .. (-315.89,-808.03)
 .. controls (-313.19,-804.25) and (-303.28,-791.64) .. (-299.68,-788.93)
 .. controls (-296.07,-786.23) and (-283.64,-771.45) .. (-279.85,-768.74)
 .. controls (-276.07,-766.04) and (-260.76,-752.52) .. (-252.84,-743.88)
 .. controls (-244.93,-735.25) and (-234.50,-726.27) .. (-228.21,-723.58)
 .. controls (-221.91,-720.89) and (-201.25,-707.27) .. (-197.30,-703.68)
 .. controls (-193.35,-700.10) and (-165.83,-679.08) .. (-159.53,-673.86)
 .. controls (-153.23,-668.64) and (-134.16,-653.88) .. (-127.86,-649.03)
 .. controls (-121.56,-644.17) and (-85.09,-607.21) .. (-80.78,-603.25)
 .. controls (-76.46,-599.30) and (-70.70,-581.48) .. (-67.81,-573.37)
 .. controls (-64.92,-565.26) and (-50.86,-541.81) .. (-48.87,-537.67)
 .. controls (-46.89,-533.53) and (-25.11,-491.77) .. (-21.87,-486.74)
 .. controls (-18.63,-481.70) and (-9.45,-470.36) .. (-6.93,-466.40)
 .. controls (-4.42,-462.44) and (15.90,-432.24) .. (17.34,-425.59)
 .. controls (18.77,-418.94) and (27.41,-401.85) .. (29.03,-396.81)
));
draw_upscrap(0)(1,((-564.70,-970.80)
 .. controls (-564.70,-970.80) and (-564.97,-959.79) .. (-565.19,-953.91)
 .. controls (-565.41,-948.03) and (-565.85,-933.23) .. (-563.60,-923.83)
 .. controls (-561.35,-914.42) and (-553.95,-896.87) .. (-553.43,-891.68)
 .. controls (-552.91,-886.50) and (-527.50,-853.71) .. (-524.11,-847.82)
 .. controls (-520.73,-841.94) and (-500.90,-822.56) .. (-493.56,-815.25)
 .. controls (-486.22,-807.93) and (-471.01,-809.69) .. (-463.67,-808.84)
 .. controls (-456.32,-808.00) and (-439.84,-814.42) .. (-433.22,-818.79)
 .. controls (-426.59,-823.17) and (-424.07,-821.37) .. (-417.43,-818.69)
 .. controls (-410.78,-816.01) and (-405.75,-816.74) .. (-405.75,-816.74)
),
1,((-405.75,-816.74)
 .. controls (-402.87,-816.03) and (-399.30,-824.35) .. (-399.13,-828.69)
 .. controls (-398.97,-833.03) and (-400.44,-846.22) .. (-399.91,-849.29)
 .. controls (-399.37,-852.36) and (-393.43,-865.15) .. (-392.35,-869.46)
 .. controls (-391.27,-873.79) and (-402.40,-890.29) .. (-405.44,-895.48)
 .. controls (-408.49,-900.68) and (-421.43,-916.31) .. (-425.76,-923.35)
 .. controls (-430.09,-930.37) and (-441.74,-937.14) .. (-449.45,-942.14)
 .. controls (-457.19,-947.16) and (-464.79,-957.51) .. (-468.78,-961.14)
 .. controls (-472.76,-964.77) and (-487.82,-973.88) .. (-492.63,-975.95)
 .. controls (-497.42,-978.01) and (-523.54,-982.27) .. (-539.33,-986.42)
 .. controls (-555.03,-990.55) and (-555.27,-985.91) .. (-558.09,-984.01)
 .. controls (-560.91,-982.11) and (-563.79,-974.02) .. (-564.70,-970.80)
));
draw_downscrap;
endfig;
beginfig(7);
ATTR__id := "l260-3396-6065";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-570.11,-1257.82)
 .. controls (-568.84,-1253.49) and (-564.15,-1238.29) .. (-559.17,-1230.55)
 .. controls (-554.17,-1222.76) and (-544.05,-1203.74) .. (-541.06,-1198.89)
 .. controls (-538.08,-1194.04) and (-522.07,-1164.20) .. (-520.77,-1161.26)
 .. controls (-519.47,-1158.32) and (-513.96,-1131.47) .. (-508.06,-1111.13)
 .. controls (-502.23,-1091.04) and (-508.84,-1069.04) .. (-509.75,-1066.72)
 .. controls (-510.66,-1064.40) and (-512.29,-1049.40) .. (-511.99,-1046.26)
 .. controls (-511.68,-1043.11) and (-505.53,-1030.68) .. (-504.19,-1026.51)
 .. controls (-502.84,-1022.34) and (-494.71,-1009.90) .. (-490.14,-1005.77)
));
ATTR__id := "l259-2880-6384";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-677.94,-1112.80)
 .. controls (-675.27,-1110.71) and (-669.69,-1108.80) .. (-663.39,-1108.57)
 .. controls (-657.23,-1108.34) and (-658.20,-1110.22) .. (-649.67,-1108.22)
 .. controls (-641.19,-1106.24) and (-644.11,-1109.62) .. (-643.01,-1112.56)
 .. controls (-641.89,-1115.53) and (-643.33,-1121.83) .. (-643.59,-1127.42)
 .. controls (-643.86,-1133.17) and (-646.64,-1151.99) .. (-647.10,-1155.16)
 .. controls (-647.56,-1158.35) and (-656.18,-1206.80) .. (-658.25,-1218.58)
 .. controls (-660.27,-1230.04) and (-658.75,-1257.37) .. (-657.67,-1261.87)
));
ATTR__id := "";
drawoptions();
p_waterflow_permanent((-293.21,-741.07),309.5,1.00,(0,0));
drawoptions();
p_waterflow_permanent((-250.00,-703.99),309.5,1.00,(0,0));
drawoptions();
p_stalagmite((-199.30,-558.28),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-169.07,-558.30),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-184.90,-544.24),0.0,1.00,(0,0));
ATTR__id := "l107-2658-7064";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-616.26,-998.75)
 .. controls (-618.17,-1005.19) and (-635.28,-1015.41) .. (-640.60,-1015.91)
 .. controls (-645.92,-1016.42) and (-665.38,-1016.59) .. (-670.12,-1018.68)
 .. controls (-674.86,-1020.76) and (-687.21,-1043.54) .. (-690.43,-1048.09)
 .. controls (-693.66,-1052.65) and (-699.19,-1059.36) .. (-702.67,-1062.30)
 .. controls (-706.16,-1065.25) and (-719.66,-1075.92) .. (-721.68,-1076.90)
));
ATTR__id := "l54-5320-8936";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-490.14,-1005.77)
 .. controls (-488.04,-1003.16) and (-483.47,-997.22) .. (-478.68,-993.90)
 .. controls (-473.86,-990.56) and (-465.78,-987.89) .. (-461.10,-987.15)
 .. controls (-456.40,-986.41) and (-436.69,-978.70) .. (-433.44,-976.89)
 .. controls (-430.21,-975.09) and (-412.45,-964.77) .. (-407.98,-960.48)
 .. controls (-403.49,-956.19) and (-395.38,-937.10) .. (-392.84,-930.04)
 .. controls (-390.31,-923.00) and (-384.92,-907.71) .. (-383.85,-902.33)
 .. controls (-382.79,-896.96) and (-381.56,-883.51) .. (-380.66,-878.65)
 .. controls (-379.76,-873.79) and (-376.15,-864.77) .. (-373.44,-859.54)
 .. controls (-370.73,-854.31) and (-362.24,-844.36) .. (-355.56,-838.93)
 .. controls (-348.88,-833.50) and (-334.99,-824.45) .. (-331.21,-822.28)
 .. controls (-327.42,-820.11) and (-318.59,-811.81) .. (-315.89,-808.03)
 .. controls (-313.19,-804.25) and (-303.28,-791.64) .. (-299.68,-788.93)
 .. controls (-296.07,-786.23) and (-283.64,-771.45) .. (-279.85,-768.74)
 .. controls (-276.07,-766.04) and (-260.76,-752.52) .. (-252.84,-743.88)
 .. controls (-244.93,-735.25) and (-234.50,-726.27) .. (-228.21,-723.58)
 .. controls (-221.91,-720.89) and (-201.25,-707.27) .. (-197.30,-703.68)
 .. controls (-193.35,-700.10) and (-165.83,-679.08) .. (-159.53,-673.86)
 .. controls (-153.23,-668.64) and (-134.16,-653.88) .. (-127.86,-649.03)
 .. controls (-121.56,-644.17) and (-85.09,-607.21) .. (-80.78,-603.25)
 .. controls (-76.46,-599.30) and (-70.70,-581.48) .. (-67.81,-573.37)
 .. controls (-64.92,-565.26) and (-50.86,-541.81) .. (-48.87,-537.67)
 .. controls (-46.89,-533.53) and (-25.11,-491.77) .. (-21.87,-486.74)
 .. controls (-18.63,-481.70) and (-9.45,-470.36) .. (-6.93,-466.40)
 .. controls (-4.42,-462.44) and (15.90,-432.24) .. (17.34,-425.59)
 .. controls (18.77,-418.94) and (27.41,-401.85) .. (29.03,-396.81)
));
ATTR__id := "l96-3588-7456";
ATTR__height := -1;
drawoptions();
l_wall_flowstone(((-405.75,-816.74)
 .. controls (-402.87,-816.03) and (-399.30,-824.35) .. (-399.13,-828.69)
 .. controls (-398.97,-833.03) and (-400.44,-846.22) .. (-399.91,-849.29)
 .. controls (-399.37,-852.36) and (-393.43,-865.15) .. (-392.35,-869.46)
 .. controls (-391.27,-873.79) and (-402.40,-890.29) .. (-405.44,-895.48)
 .. controls (-408.49,-900.68) and (-421.43,-916.31) .. (-425.76,-923.35)
 .. controls (-430.09,-930.37) and (-441.74,-937.14) .. (-449.45,-942.14)
 .. controls (-457.19,-947.16) and (-464.79,-957.51) .. (-468.78,-961.14)
 .. controls (-472.76,-964.77) and (-487.82,-973.88) .. (-492.63,-975.95)
 .. controls (-497.42,-978.01) and (-523.54,-982.27) .. (-539.33,-986.42)
 .. controls (-555.03,-990.55) and (-555.27,-985.91) .. (-558.09,-984.01)
 .. controls (-560.91,-982.11) and (-563.79,-974.02) .. (-564.70,-970.80)
));
ATTR__id := "l52-4360-9108";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-99.61,-340.90)
 .. controls (-101.41,-347.38) and (-108.97,-370.59) .. (-108.97,-376.35)
 .. controls (-108.97,-382.11) and (-115.47,-416.15) .. (-117.63,-422.28)
 .. controls (-119.79,-428.40) and (-124.83,-435.60) .. (-126.99,-440.82)
 .. controls (-129.15,-446.04) and (-143.90,-478.59) .. (-146.41,-485.42)
 .. controls (-148.93,-492.26) and (-159.89,-518.88) .. (-162.05,-522.29)
 .. controls (-164.21,-525.71) and (-180.40,-532.17) .. (-191.01,-534.86)
 .. controls (-201.62,-537.55) and (-229.68,-546.16) .. (-237.96,-548.49)
 .. controls (-246.23,-550.82) and (-288.66,-573.61) .. (-297.11,-580.25)
 .. controls (-305.56,-586.90) and (-335.59,-614.02) .. (-340.26,-620.86)
 .. controls (-344.94,-627.69) and (-378.97,-663.53) .. (-382.77,-673.45)
 .. controls (-386.57,-683.38) and (-397.02,-697.99) .. (-400.27,-703.03)
 .. controls (-403.51,-708.08) and (-416.81,-719.92) .. (-420.95,-731.98)
 .. controls (-425.08,-744.03) and (-440.69,-771.32) .. (-446.97,-777.95)
 .. controls (-453.25,-784.58) and (-466.87,-786.82) .. (-471.35,-787.33)
 .. controls (-475.83,-787.84) and (-489.97,-791.50) .. (-503.58,-807.58)
 .. controls (-517.16,-823.63) and (-524.48,-831.64) .. (-529.29,-838.77)
 .. controls (-534.11,-845.89) and (-539.63,-847.96) .. (-551.89,-865.71)
 .. controls (-564.11,-883.40) and (-570.65,-890.41) .. (-572.56,-899.83)
 .. controls (-574.46,-909.25) and (-584.88,-932.95) .. (-588.16,-939.75)
 .. controls (-591.42,-946.52) and (-598.80,-958.02) .. (-603.58,-965.17)
 .. controls (-608.34,-972.28) and (-611.67,-979.78) .. (-613.27,-986.12)
 .. controls (-614.86,-992.44) and (-616.40,-999.95) .. (-616.40,-999.95)
));
ATTR__id := "l94-4212-8378";
ATTR__height := -1;
drawoptions();
l_wall_flowstone(((-564.70,-970.80)
 .. controls (-564.70,-970.80) and (-564.97,-959.79) .. (-565.19,-953.91)
 .. controls (-565.41,-948.03) and (-565.85,-933.23) .. (-563.60,-923.83)
 .. controls (-561.35,-914.42) and (-553.95,-896.87) .. (-553.43,-891.68)
 .. controls (-552.91,-886.50) and (-527.50,-853.71) .. (-524.11,-847.82)
 .. controls (-520.73,-841.94) and (-500.90,-822.56) .. (-493.56,-815.25)
 .. controls (-486.22,-807.93) and (-471.01,-809.69) .. (-463.67,-808.84)
 .. controls (-456.32,-808.00) and (-439.84,-814.42) .. (-433.22,-818.79)
 .. controls (-426.59,-823.17) and (-424.07,-821.37) .. (-417.43,-818.69)
 .. controls (-410.78,-816.01) and (-405.75,-816.74) .. (-405.75,-816.74)
));
ATTR__id := "";
drawoptions();
p_sodastraw((370.14,547.83),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((449.70,655.85),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((445.74,595.72),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((528.89,748.35),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((579.30,927.27),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((546.18,1004.67),0.0,1.00,(0,0));
drawoptions();
p_stalactite((415.50,615.16),0.0,1.00,(0,0));
drawoptions();
p_stalactite((492.18,654.04),0.0,1.00,(0,0));
drawoptions();
p_stalactite((478.14,698.32),0.0,1.00,(0,0));
drawoptions();
p_stalactite((541.85,784.71),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((569.94,817.48),0.0,1.00,(0,0));
ATTR__id := "l30-9984-17468";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((29.03,-396.81)
 .. controls (33.17,-388.16) and (25.98,-371.59) .. (33.91,-351.41)
 .. controls (41.83,-331.25) and (51.91,-313.25) .. (48.30,-291.66)
 .. controls (44.70,-270.06) and (41.81,-243.43) .. (38.21,-232.64)
 .. controls (34.60,-221.85) and (35.33,-199.52) .. (36.06,-186.55)
 .. controls (36.78,-173.59) and (35.35,-149.82) .. (46.87,-132.54)
 .. controls (58.39,-115.26) and (72.07,-80.71) .. (92.23,-64.86)
 .. controls (112.39,-49.02) and (153.42,-6.56) .. (160.62,6.40)
 .. controls (167.82,19.37) and (204.56,52.51) .. (210.32,65.47)
 .. controls (216.08,78.43) and (239.12,122.34) .. (242.71,133.86)
 .. controls (246.31,145.37) and (252.78,214.47) .. (294.55,245.45)
 .. controls (336.31,276.42) and (336.31,313.85) .. (342.07,323.93)
 .. controls (347.83,334.01) and (350.71,386.56) .. (350.70,390.88)
 .. controls (350.70,395.20) and (352.86,418.96) .. (361.50,434.08)
 .. controls (370.14,449.20) and (385.26,470.07) .. (392.45,480.87)
 .. controls (399.65,491.66) and (416.21,523.35) .. (421.98,529.83)
 .. controls (427.74,536.31) and (454.38,554.31) .. (463.02,564.40)
 .. controls (471.66,574.48) and (545.10,654.40) .. (551.57,666.64)
 .. controls (558.05,678.87) and (563.81,701.91) .. (568.13,713.43)
 .. controls (572.45,724.95) and (583.97,735.03) .. (590.45,744.40)
 .. controls (596.93,753.76) and (617.82,779.68) .. (617.82,790.48)
 .. controls (617.82,801.28) and (626.46,830.80) .. (636.54,847.36)
 .. controls (646.62,863.92) and (650.94,902.80) .. (650.94,908.56)
 .. controls (650.94,914.32) and (656.71,962.56) .. (654.55,974.79)
 .. controls (652.38,987.03) and (644.46,1010.07) .. (653.11,1029.52)
 .. controls (661.75,1048.96) and (676.87,1077.76) .. (683.35,1089.28)
 .. controls (689.83,1100.80) and (705.67,1128.17) .. (704.23,1140.41)
 .. controls (702.79,1152.65) and (700.81,1174.79) .. (674.88,1181.98)
 .. controls (648.96,1189.18) and (612.78,1192.96) .. (600.54,1192.23)
 .. controls (588.30,1191.51) and (559.50,1186.47) .. (544.38,1205.19)
 .. controls (529.26,1223.90) and (532.86,1215.27) .. (530.70,1221.03)
));
ATTR__id := "l29-9392-18376";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((515.58,1191.51)
 .. controls (527.10,1194.39) and (525.66,1197.27) .. (535.74,1182.15)
 .. controls (545.82,1167.03) and (539.34,1138.95) .. (536.46,1126.00)
 .. controls (533.58,1113.04) and (524.22,1084.95) .. (527.10,1074.15)
 .. controls (529.98,1063.35) and (524.22,1028.07) .. (521.34,1010.79)
 .. controls (518.46,993.51) and (514.14,954.63) .. (514.86,939.51)
 .. controls (515.58,924.39) and (515.58,874.71) .. (511.98,858.15)
 .. controls (508.37,841.59) and (506.21,829.35) .. (506.21,810.63)
 .. controls (506.21,791.91) and (496.13,750.87) .. (482.46,737.92)
 .. controls (468.78,724.96) and (439.26,681.05) .. (432.06,666.65)
 .. controls (424.86,652.25) and (393.90,611.20) .. (388.86,604.71)
 .. controls (383.82,598.23) and (360.06,575.92) .. (352.86,558.64)
 .. controls (345.66,541.36) and (341.34,514.00) .. (334.14,497.44)
 .. controls (326.94,480.88) and (307.50,429.74) .. (303.90,418.94)
 .. controls (300.30,408.14) and (280.86,341.91) .. (277.26,335.43)
 .. controls (273.65,328.95) and (247.74,289.36) .. (234.79,280.73)
 .. controls (221.83,272.09) and (181.52,236.10) .. (174.32,219.54)
 .. controls (167.12,202.98) and (128.22,139.60) .. (126.06,121.60)
 .. controls (123.90,103.61) and (110.23,76.98) .. (103.76,70.50)
 .. controls (97.28,64.03) and (69.92,37.38) .. (62.72,23.70)
 .. controls (55.51,10.01) and (27.43,-35.35) .. (27.42,-45.43)
 .. controls (27.42,-55.52) and (-2.81,-100.14) .. (-10.01,-117.43)
 .. controls (-17.22,-134.72) and (-44.57,-192.30) .. (-50.32,-208.84)
 .. controls (-56.08,-225.39) and (-79.83,-288.73) .. (-84.87,-303.85)
 .. controls (-89.90,-318.96) and (-99.61,-340.90) .. (-99.61,-340.90)
));
ATTR__id := "l29-3238-5890";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-660.91,-1257.37)
 .. controls (-659.47,-1260.07) and (-654.79,-1263.84) .. (-652.43,-1265.25)
 .. controls (-650.07,-1266.66) and (-645.70,-1268.56) .. (-643.34,-1268.34)
 .. controls (-640.97,-1268.12) and (-639.69,-1268.99) .. (-634.23,-1265.83)
 .. controls (-628.77,-1262.67) and (-620.24,-1261.47) .. (-618.78,-1257.84)
 .. controls (-617.32,-1254.20) and (-615.06,-1254.69) .. (-614.08,-1254.20)
 .. controls (-612.64,-1253.48) and (-609.68,-1253.86) .. (-607.64,-1255.71)
 .. controls (-606.22,-1257.00) and (-603.25,-1259.93) .. (-602.31,-1261.76)
 .. controls (-600.35,-1265.58) and (-599.46,-1267.39) .. (-595.36,-1267.47)
 .. controls (-591.27,-1267.54) and (-588.25,-1265.45) .. (-584.33,-1263.54)
 .. controls (-580.41,-1261.62) and (-577.55,-1260.57) .. (-575.04,-1259.33)
 .. controls (-572.53,-1258.09) and (-566.96,-1256.47) .. (-566.96,-1256.47)
));
endfig;
beginfig(8);
ATTR__id := "";
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char67 \char111 \char110 \char115 \char112 \char105 \char114 \char97 \char99 \char121 \ \char68 \char117 \char99 \char107 \mainfont{} etex,(622.86,1231.84),0.0,0);
endfig;
background:=(0.25000,0.25750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.25750, 1.00000);
current_scrap := "romeoSP3@romeo_entrance.romeo";
ATTR__scrap := "romeoSP3";
beginfig(9);
current_src := "Romeo_entrance.th2 [3175]";
string area_border[];
area_border[1] := "l340-3144-39906";
drawoptions();
a_water(buildcycle(((-246.84,105.27)
 .. controls (-246.84,105.27) and (-241.54,78.26) .. (-238.56,61.70)
 .. controls (-235.53,44.92) and (-293.67,34.36) .. (-290.44,30.05)
 .. controls (-287.20,25.73) and (-294.43,0.19) .. (-306.31,-3.04)
 .. controls (-318.19,-6.26) and (-343.79,-4.46) .. (-343.79,-4.46)
 -- (-357.06,23.58)
 -- (-337.24,55.63)
 -- (-305.94,72.57)
 -- (-269.20,94.86)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2982]";
string area_border[];
area_border[1] := "l318-6244-40656";
drawoptions();
a_blocks(buildcycle(((263.71,217.56)
 -- (277.03,195.24)
 .. controls (277.03,195.24) and (353.36,222.58) .. (352.27,223.66)
 .. controls (351.19,224.74) and (339.67,254.27) .. (339.67,254.27)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2978]";
string area_border[];
area_border[1] := "l319-5706-40728";
drawoptions();
a_blocks(buildcycle(((159.29,248.90)
 -- (194.96,186.59)
 -- (220.14,228.00)
 -- (194.57,248.53)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2958]";
string area_border[];
area_border[1] := "l320-5656-40364";
drawoptions();
a_blocks(buildcycle(((136.25,149.54)
 -- (183.76,129.03)
 -- (220.13,144.86)
 -- (189.91,180.83)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2954]";
string area_border[];
area_border[1] := "l321-5352-40272";
drawoptions();
a_blocks(buildcycle(((129.78,161.77)
 -- (151.02,168.97)
 -- (138.77,240.97)
 -- (129.05,239.89)
 -- (123.31,202.43)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2887]";
string area_border[];
area_border[1] := "l338-4802-40752";
drawoptions();
a_clay(buildcycle(((-137.33,126.46)
 -- (-154.97,150.58)
 .. controls (-154.97,150.58) and (-121.86,201.71) .. (-103.15,208.55)
 .. controls (-84.44,215.40) and (-47.34,239.51) .. (-25.75,239.51)
 .. controls (-4.15,239.52) and (39.06,262.91) .. (63.90,237.35)
 .. controls (82.22,218.51) and (99.20,200.27) .. (99.20,200.27)
 -- (90.55,176.52)
 -- (37.28,197.74)
 -- (-17.86,138.03)
 .. controls (-17.86,138.03) and (-36.94,146.66) .. (-38.38,148.82)
 .. controls (-39.81,150.98) and (-12.07,197.76) .. (-12.07,197.76)
 -- (-44.46,204.22)
 -- (-105.67,138.72)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2769]";
string area_border[];
area_border[1] := "l267-2482-38356";
area_border[2] := "l310-2810-37896";
area_border[3] := "l268-3082-37962";
area_border[4] := "l272-3132-38192";
drawoptions();
a_water(buildcycle(((-363.78,-191.50)
 -- (-412.91,-177.30)
 -- (-420.56,-216.41)
 -- (-425.76,-270.79)
 -- (-378.93,-273.77)
 -- (-341.12,-261.10)
),
((-341.12,-261.10)
 .. controls (-341.12,-261.10) and (-321.75,-254.08) .. (-299.34,-266.00)
),
((-299.34,-266.00)
 -- (-251.02,-237.78)
 -- (-252.74,-221.23)
 -- (-265.71,-210.90)
),
((-265.71,-210.90)
 .. controls (-284.41,-196.88) and (-281.11,-202.91) .. (-311.15,-198.00)
 .. controls (-340.75,-193.16) and (-350.08,-195.72) .. (-363.78,-191.50)
)));
current_src := "Romeo_entrance.th2 [2756]";
string area_border[];
area_border[1] := "l349-3490-40082";
drawoptions();
a_clay(buildcycle(((-234.21,114.24)
 -- (-218.00,67.79)
 -- (-185.93,83.62)
 -- (-170.46,113.14)
 -- (-185.94,134.75)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2735]";
string area_border[];
area_border[1] := "l342-3290-39068";
drawoptions();
a_blocks(buildcycle(((-324.98,-124.89)
 -- (-273.50,-123.42)
 -- (-238.28,-52.10)
 .. controls (-238.28,-52.10) and (-321.95,-60.83) .. (-324.68,-53.48)
 .. controls (-327.36,-46.29) and (-324.98,-124.89) .. cycle
)));
ATTR__id := "l310-2810-37896";
ATTR__height := -1;
drawoptions();
l_flowstone(((-341.12,-261.10)
 .. controls (-341.12,-261.10) and (-321.75,-254.08) .. (-299.34,-266.00)
));
ATTR__id := "l272-3132-38192";
ATTR__height := -1;
drawoptions();
l_floorstep(((-265.71,-210.90)
 .. controls (-284.41,-196.88) and (-281.11,-202.91) .. (-311.15,-198.00)
 .. controls (-340.75,-193.16) and (-350.08,-195.72) .. (-363.78,-191.50)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_floorstep(((96.31,178.67)
 .. controls (113.95,177.23) and (127.24,140.55) .. (135.15,121.84)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((126.17,143.78)
 .. controls (138.76,128.31) and (169.36,122.55) .. (191.68,125.43)
 .. controls (214.00,128.31) and (250.74,157.81) .. (261.54,164.65)
 .. controls (272.34,171.49) and (287.83,197.40) .. (299.35,202.44)
 .. controls (310.87,207.47) and (351.92,215.38) .. (353.00,216.10)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((101.36,197.75)
 .. controls (101.36,189.83) and (101.36,180.47) .. (100.64,178.67)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((219.06,250.69)
 .. controls (219.06,250.69) and (253.62,268.33) .. (228.79,234.85)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((267.31,238.44)
 .. controls (267.31,238.44) and (264.79,252.85) .. (279.55,256.44)
 .. controls (294.31,260.04) and (293.95,245.27) .. (290.35,238.79)
));
ATTR__height := -1;
drawoptions();
l_pit(((238.51,236.64)
 .. controls (243.20,221.52) and (243.20,215.03) .. (251.84,215.39)
 .. controls (260.48,215.75) and (266.23,227.64) .. (266.23,230.52)
 .. controls (266.23,233.40) and (264.43,240.96) .. (264.43,240.96)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((144.90,225.85)
 .. controls (144.90,225.85) and (146.34,214.68) .. (146.70,210.36)
 .. controls (147.06,206.04) and (149.58,168.97) .. (171.55,174.35)
 .. controls (176.56,175.58) and (186.31,196.67) .. (186.31,196.67)
 .. controls (186.31,196.67) and (171.53,231.61) .. (163.61,233.05)
 .. controls (152.63,235.05) and (144.90,225.85) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((220.51,221.88)
 -- (233.47,209.27)
 -- (221.59,193.08)
 .. controls (221.59,193.08) and (211.87,200.64) .. (210.79,204.60)
 .. controls (209.71,208.56) and (220.51,221.88) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((214.39,187.68)
 -- (210.07,171.12)
 .. controls (210.07,171.12) and (215.82,161.41) .. (217.98,159.97)
 .. controls (220.14,158.53) and (225.18,154.57) .. (226.98,163.57)
 .. controls (228.79,172.56) and (231.67,183.00) .. (231.67,183.00)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((253.28,195.95)
 -- (253.99,179.04)
 -- (261.91,179.40)
 -- (269.11,194.52)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((233.11,191.64)
 -- (250.76,191.64)
 -- (251.11,170.05)
 -- cycle
));
ATTR__id := "l318-6244-40656";
ATTR__height := -1;
drawoptions();
l_border_invisible(((263.71,217.56)
 -- (277.03,195.24)
 .. controls (277.03,195.24) and (353.36,222.58) .. (352.27,223.66)
 .. controls (351.19,224.74) and (339.67,254.27) .. (339.67,254.27)
 -- cycle
));
ATTR__id := "l319-5706-40728";
ATTR__height := -1;
drawoptions();
l_border_invisible(((159.29,248.90)
 -- (194.96,186.59)
 -- (220.14,228.00)
 -- (194.57,248.53)
 -- cycle
));
ATTR__id := "l320-5656-40364";
ATTR__height := -1;
drawoptions();
l_border_invisible(((136.25,149.54)
 -- (183.76,129.03)
 -- (220.13,144.86)
 -- (189.91,180.83)
 -- cycle
));
ATTR__id := "l321-5352-40272";
ATTR__height := -1;
drawoptions();
l_border_invisible(((129.78,161.77)
 -- (151.02,168.97)
 -- (138.77,240.97)
 -- (129.05,239.89)
 -- (123.31,202.43)
 -- cycle
));
ATTR__id := "l338-4802-40752";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-137.33,126.46)
 -- (-154.97,150.58)
 .. controls (-154.97,150.58) and (-121.86,201.71) .. (-103.15,208.55)
 .. controls (-84.44,215.40) and (-47.34,239.51) .. (-25.75,239.51)
 .. controls (-4.15,239.52) and (39.06,262.91) .. (63.90,237.35)
 .. controls (82.22,218.51) and (99.20,200.27) .. (99.20,200.27)
 -- (90.55,176.52)
 -- (37.28,197.74)
 -- (-17.86,138.03)
 .. controls (-17.86,138.03) and (-36.94,146.66) .. (-38.38,148.82)
 .. controls (-39.81,150.98) and (-12.07,197.76) .. (-12.07,197.76)
 -- (-44.46,204.22)
 -- (-105.67,138.72)
 -- cycle
));
ATTR__id := "l340-3144-39906";
ATTR__height := -1;
drawoptions();
l_border_visible(((-246.84,105.27)
 .. controls (-246.84,105.27) and (-241.54,78.26) .. (-238.56,61.70)
 .. controls (-235.53,44.92) and (-293.67,34.36) .. (-290.44,30.05)
 .. controls (-287.20,25.73) and (-294.43,0.19) .. (-306.31,-3.04)
 .. controls (-318.19,-6.26) and (-343.79,-4.46) .. (-343.79,-4.46)
 -- (-357.06,23.58)
 -- (-337.24,55.63)
 -- (-305.94,72.57)
 -- (-269.20,94.86)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_floorstep(((335.35,276.94)
 -- (301.15,238.79)
 -- (290.35,238.79)
 .. controls (290.35,238.79) and (282.07,225.12) .. (269.47,237.72)
 .. controls (256.87,250.33) and (227.35,230.88) .. (228.79,234.85)
 .. controls (230.22,238.81) and (192.78,226.93) .. (219.06,250.69)
 .. controls (228.27,259.02) and (167.21,259.34) .. (148.48,261.50)
 .. controls (129.76,263.66) and (118.24,275.54) .. (106.37,251.05)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((139.84,262.58)
 .. controls (139.84,262.58) and (113.59,247.81) .. (117.56,201.71)
 .. controls (121.52,155.65) and (122.58,158.53) .. (123.65,147.38)
));
ATTR__id := "l268-3082-37962";
ATTR__height := -1;
drawoptions();
l_border_visible(((-299.34,-266.00)
 -- (-251.02,-237.78)
 -- (-252.74,-221.23)
 -- (-265.71,-210.90)
));
ATTR__id := "l267-2482-38356";
ATTR__height := -1;
drawoptions();
l_border_visible(((-363.78,-191.50)
 -- (-412.91,-177.30)
 -- (-420.56,-216.41)
 -- (-425.76,-270.79)
 -- (-378.93,-273.77)
 -- (-341.12,-261.10)
));
ATTR__id := "l349-3490-40082";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-234.21,114.24)
 -- (-218.00,67.79)
 -- (-185.93,83.62)
 -- (-170.46,113.14)
 -- (-185.94,134.75)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_border_visible(((-288.00,-124.67)
 -- (-317.60,-124.97)
));
ATTR__id := "l342-3290-39068";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-324.98,-124.89)
 -- (-273.50,-123.42)
 -- (-238.28,-52.10)
 .. controls (-238.28,-52.10) and (-321.95,-60.83) .. (-324.68,-53.48)
 .. controls (-327.36,-46.29) and (-324.98,-124.89) .. cycle
));
endfig;
beginfig(10);
draw_upscrap(1)(1,((-388.94,-255.12)
 .. controls (-387.77,-256.85) and (-374.67,-255.31) .. (-373.27,-255.07)
 .. controls (-371.87,-254.82) and (-362.47,-253.96) .. (-358.31,-254.65)
 .. controls (-354.12,-255.35) and (-344.42,-255.62) .. (-341.12,-261.10)
 .. controls (-337.75,-266.71) and (-338.38,-268.49) .. (-335.23,-269.93)
 .. controls (-332.10,-271.35) and (-319.82,-276.95) .. (-312.45,-273.37)
 .. controls (-305.03,-269.75) and (-289.75,-264.90) .. (-283.14,-253.87)
 .. controls (-276.39,-242.62) and (-273.35,-238.61) .. (-272.19,-234.63)
 .. controls (-271.02,-230.62) and (-267.02,-224.08) .. (-265.63,-218.62)
 .. controls (-264.23,-213.10) and (-263.50,-207.35) .. (-263.85,-200.26)
 .. controls (-264.21,-193.15) and (-263.72,-173.95) .. (-263.71,-169.76)
 .. controls (-263.70,-165.58) and (-263.16,-156.09) .. (-267.69,-149.29)
 .. controls (-272.21,-142.50) and (-275.60,-139.99) .. (-277.89,-137.81)
 .. controls (-280.19,-135.63) and (-287.85,-130.24) .. (-289.01,-128.35)
 .. controls (-290.10,-126.56) and (-291.13,-125.46) .. (-288.00,-124.67)
 .. controls (-284.97,-123.90) and (-278.88,-120.42) .. (-274.90,-115.76)
 .. controls (-270.92,-111.08) and (-260.25,-90.03) .. (-259.94,-86.16)
 .. controls (-259.62,-82.29) and (-249.55,-56.67) .. (-248.77,-50.88)
 .. controls (-247.98,-45.09) and (-247.54,-31.00) .. (-247.89,-26.75)
 .. controls (-248.24,-22.51) and (-249.80,-17.51) .. (-249.26,-12.94)
 .. controls (-248.72,-8.37) and (-249.28,-4.83) .. (-247.05,-2.06)
 .. controls (-244.80,0.74) and (-242.37,8.39) .. (-243.56,12.35)
 .. controls (-244.75,16.31) and (-248.98,24.48) .. (-255.36,24.22)
 .. controls (-261.78,23.95) and (-270.77,20.33) .. (-274.03,21.41)
 .. controls (-277.28,22.49) and (-289.36,22.49) .. (-291.16,24.29)
 .. controls (-292.96,26.08) and (-298.16,28.41) .. (-294.04,34.54)
 .. controls (-289.91,40.67) and (-277.50,48.96) .. (-273.90,50.58)
 .. controls (-270.29,52.20) and (-251.55,63.35) .. (-248.49,65.15)
 .. controls (-245.42,66.94) and (-237.31,68.73) .. (-234.60,69.09)
 .. controls (-231.89,69.44) and (-222.52,76.99) .. (-220.53,76.98)
 .. controls (-218.55,76.98) and (-209.53,81.65) .. (-207.73,82.01)
 .. controls (-205.93,82.37) and (-203.41,79.85) .. (-201.43,81.64)
 .. controls (-199.44,83.44) and (-192.59,90.45) .. (-189.89,90.45)
 .. controls (-187.19,90.45) and (-183.95,89.91) .. (-179.27,90.10)
 .. controls (-174.60,90.28) and (-158.58,95.86) .. (-155.87,98.20)
 .. controls (-153.17,100.54) and (-146.69,103.23) .. (-145.43,104.85)
 .. controls (-144.16,106.47) and (-144.70,107.91) .. (-144.88,111.87)
 .. controls (-145.06,115.83) and (-146.33,121.96) .. (-144.71,127.36)
 .. controls (-143.08,132.76) and (-137.15,146.26) .. (-132.29,148.78)
 .. controls (-127.44,151.31) and (-116.64,154.01) .. (-114.30,154.01)
 .. controls (-111.96,154.01) and (-108.73,152.22) .. (-108.01,150.60)
 .. controls (-107.29,148.98) and (-106.21,144.66) .. (-104.59,147.54)
 .. controls (-102.97,150.42) and (-97.57,153.84) .. (-95.77,158.34)
 .. controls (-93.97,162.84) and (-87.85,171.48) .. (-83.72,174.72)
 .. controls (-79.58,177.96) and (-68.41,191.82) .. (-66.43,194.16)
 .. controls (-64.45,196.49) and (-49.85,209.97) .. (-47.51,209.97)
 .. controls (-45.17,209.97) and (-36.35,210.34) .. (-30.06,209.80)
 .. controls (-23.76,209.27) and (-15.49,208.91) .. (-11.71,207.66)
 .. controls (-7.93,206.40) and (-2.35,206.58) .. (-1.45,202.26)
 .. controls (-0.55,197.94) and (0.17,194.70) .. (-5.95,187.14)
 .. controls (-12.08,179.59) and (-12.26,178.15) .. (-16.04,173.11)
 .. controls (-19.82,168.08) and (-23.43,164.12) .. (-27.21,159.62)
 .. controls (-30.99,155.12) and (-32.97,152.78) .. (-32.97,152.78)
),
1,((-20.38,145.23)
 .. controls (-16.41,148.83) and (9.17,183.72) .. (14.94,189.12)
 .. controls (20.71,194.51) and (33.31,208.54) .. (45.20,199.54)
 .. controls (57.07,190.55) and (81.91,184.80) .. (84.43,184.08)
 .. controls (86.95,183.35) and (102.78,179.74) .. (95.59,171.84)
 .. controls (91.98,167.88) and (82.26,166.81) .. (76.50,165.37)
 .. controls (70.73,163.93) and (57.77,163.21) .. (61.73,157.10)
 .. controls (65.69,150.98) and (68.56,140.91) .. (75.04,136.23)
 .. controls (81.51,131.56) and (98.80,130.12) .. (105.99,127.96)
 .. controls (113.19,125.80) and (141.99,120.76) .. (147.03,117.16)
 .. controls (152.07,113.56) and (171.15,107.45) .. (183.03,109.25)
 .. controls (194.91,111.04) and (228.41,134.07) .. (236.69,140.18)
 .. controls (244.97,146.30) and (273.78,168.25) .. (281.34,175.45)
 .. controls (288.90,182.65) and (312.66,185.88) .. (318.07,189.48)
 .. controls (323.47,193.08) and (348.32,214.30) .. (348.32,214.30)
 -- (353.00,216.10)
),
1,((333.55,285.22)
 .. controls (333.55,285.22) and (322.57,280.54) .. (313.57,280.55)
 .. controls (304.57,280.55) and (294.31,278.76) .. (284.41,278.76)
 .. controls (274.50,278.77) and (277.56,276.78) .. (267.48,276.25)
 .. controls (257.40,275.71) and (244.80,276.43) .. (238.31,277.52)
 .. controls (231.83,278.60) and (220.13,278.60) .. (213.11,279.14)
 .. controls (206.09,279.68) and (193.30,278.06) .. (185.38,283.29)
 .. controls (177.46,288.51) and (178.54,297.51) .. (167.92,296.79)
 .. controls (157.29,296.07) and (150.27,294.63) .. (144.33,292.47)
 .. controls (138.39,290.31) and (121.65,289.23) .. (114.10,281.48)
 .. controls (106.54,273.74) and (102.94,269.78) .. (104.93,259.87)
 .. controls (106.91,249.97) and (107.10,240.79) .. (107.28,235.93)
 .. controls (107.46,231.06) and (105.31,218.28) .. (104.05,213.05)
 .. controls (102.80,207.83) and (102.62,199.01) .. (101.36,197.75)
 .. controls (100.10,196.49) and (99.38,193.97) .. (95.42,198.65)
 .. controls (91.45,203.33) and (88.75,211.26) .. (85.51,213.78)
 .. controls (82.27,216.30) and (73.44,220.44) .. (67.68,223.67)
 .. controls (61.93,226.91) and (52.39,232.66) .. (50.23,236.08)
 .. controls (48.07,239.50) and (45.73,247.96) .. (40.15,245.98)
 .. controls (34.57,244.00) and (12.06,240.05) .. (0.17,237.90)
 .. controls (-11.71,235.74) and (-35.82,234.46) .. (-41.76,231.94)
 .. controls (-47.69,229.41) and (-51.47,231.76) .. (-57.60,226.72)
 .. controls (-63.72,221.68) and (-89.12,211.26) .. (-94.87,205.50)
 .. controls (-100.63,199.73) and (-116.27,193.24) .. (-117.71,190.71)
 .. controls (-119.14,188.19) and (-122.02,186.03) .. (-124.54,185.85)
 .. controls (-127.06,185.67) and (-127.78,184.59) .. (-129.58,179.73)
 .. controls (-131.39,174.87) and (-145.07,157.06) .. (-146.69,152.92)
 .. controls (-148.31,148.78) and (-151.36,142.65) .. (-154.06,140.67)
 .. controls (-156.76,138.69) and (-163.25,138.70) .. (-163.61,137.26)
),
1,((-164.33,132.94)
 .. controls (-164.69,131.50) and (-158.57,130.78) .. (-157.67,125.74)
 .. controls (-156.77,120.70) and (-151.18,113.85) .. (-156.76,111.33)
 .. controls (-162.35,108.82) and (-168.48,107.38) .. (-171.54,105.58)
 .. controls (-174.60,103.78) and (-179.28,103.96) .. (-179.28,108.64)
 .. controls (-179.28,113.33) and (-177.30,118.55) .. (-176.58,121.07)
 .. controls (-175.86,123.59) and (-172.22,128.19) .. (-169.73,130.42)
 .. controls (-166.13,133.66) and (-166.13,132.40) .. (-169.73,130.42)
),
1,((-173.16,133.13)
 .. controls (-176.76,131.15) and (-178.02,128.99) .. (-183.60,127.37)
 .. controls (-189.18,125.75) and (-194.04,120.52) .. (-199.79,118.53)
 .. controls (-205.55,116.55) and (-215.28,112.96) .. (-218.70,111.34)
 .. controls (-222.13,109.73) and (-236.02,104.35) .. (-245.22,98.25)
 .. controls (-254.42,92.14) and (-268.13,86.58) .. (-273.00,82.45)
 .. controls (-277.86,78.32) and (-290.83,71.66) .. (-294.07,68.06)
 .. controls (-297.31,64.45) and (-303.42,58.68) .. (-307.19,55.98)
 .. controls (-310.96,53.27) and (-319.75,48.93) .. (-324.96,46.40)
 .. controls (-330.17,43.87) and (-337.01,41.53) .. (-340.80,39.19)
 .. controls (-344.58,36.86) and (-350.18,29.49) .. (-349.27,24.80)
 .. controls (-348.37,20.12) and (-347.29,17.78) .. (-343.14,12.19)
 .. controls (-339.01,6.62) and (-339.93,3.57) .. (-334.16,1.95)
 .. controls (-328.41,0.33) and (-323.90,0.69) .. (-320.12,1.77)
 .. controls (-316.34,2.85) and (-308.80,2.32) .. (-306.11,1.25)
 .. controls (-303.42,0.18) and (-300.73,-1.60) .. (-300.19,-3.74)
),
1,((-300.19,-3.74)
 -- (-303.44,-6.59)
),
1,reverse ((-299.69,-14.45)
 -- (-306.03,-17.44)
),
1,((-299.69,-14.45)
 .. controls (-303.00,-19.79) and (-302.16,-25.01) .. (-306.23,-32.39)
 .. controls (-310.32,-39.79) and (-315.45,-46.50) .. (-316.66,-50.85)
 .. controls (-317.88,-55.23) and (-319.64,-61.69) .. (-319.86,-64.77)
 .. controls (-320.09,-67.88) and (-321.17,-80.86) .. (-321.12,-86.21)
 .. controls (-321.06,-91.60) and (-320.23,-97.22) .. (-319.51,-103.24)
 .. controls (-318.79,-109.30) and (-319.01,-111.70) .. (-318.29,-113.54)
 .. controls (-317.56,-115.38) and (-317.18,-114.27) .. (-316.26,-118.88)
 .. controls (-315.35,-123.48) and (-315.32,-124.21) .. (-317.60,-124.97)
 .. controls (-319.87,-125.73) and (-321.93,-125.03) .. (-322.96,-131.33)
 .. controls (-323.99,-137.66) and (-323.25,-144.60) .. (-325.50,-149.46)
 .. controls (-327.77,-154.38) and (-337.17,-165.31) .. (-341.92,-172.33)
 .. controls (-346.69,-179.39) and (-349.87,-179.98) .. (-354.65,-184.08)
 .. controls (-359.33,-188.09) and (-360.63,-190.17) .. (-363.78,-191.50)
 .. controls (-366.89,-192.80) and (-365.25,-193.28) .. (-371.10,-192.42)
));
draw_downscrap;
endfig;
beginfig(11);
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-388.94,-255.12)
 .. controls (-387.77,-256.85) and (-374.67,-255.31) .. (-373.27,-255.07)
 .. controls (-371.87,-254.82) and (-362.47,-253.96) .. (-358.31,-254.65)
 .. controls (-354.12,-255.35) and (-344.42,-255.62) .. (-341.12,-261.10)
 .. controls (-337.75,-266.71) and (-338.38,-268.49) .. (-335.23,-269.93)
 .. controls (-332.10,-271.35) and (-319.82,-276.95) .. (-312.45,-273.37)
 .. controls (-305.03,-269.75) and (-289.75,-264.90) .. (-283.14,-253.87)
 .. controls (-276.39,-242.62) and (-273.35,-238.61) .. (-272.19,-234.63)
 .. controls (-271.02,-230.62) and (-267.02,-224.08) .. (-265.63,-218.62)
 .. controls (-264.23,-213.10) and (-263.50,-207.35) .. (-263.85,-200.26)
 .. controls (-264.21,-193.15) and (-263.72,-173.95) .. (-263.71,-169.76)
 .. controls (-263.70,-165.58) and (-263.16,-156.09) .. (-267.69,-149.29)
 .. controls (-272.21,-142.50) and (-275.60,-139.99) .. (-277.89,-137.81)
 .. controls (-280.19,-135.63) and (-287.85,-130.24) .. (-289.01,-128.35)
 .. controls (-290.10,-126.56) and (-291.13,-125.46) .. (-288.00,-124.67)
 .. controls (-284.97,-123.90) and (-278.88,-120.42) .. (-274.90,-115.76)
 .. controls (-270.92,-111.08) and (-260.25,-90.03) .. (-259.94,-86.16)
 .. controls (-259.62,-82.29) and (-249.55,-56.67) .. (-248.77,-50.88)
 .. controls (-247.98,-45.09) and (-247.54,-31.00) .. (-247.89,-26.75)
 .. controls (-248.24,-22.51) and (-249.80,-17.51) .. (-249.26,-12.94)
 .. controls (-248.72,-8.37) and (-249.28,-4.83) .. (-247.05,-2.06)
 .. controls (-244.80,0.74) and (-242.37,8.39) .. (-243.56,12.35)
 .. controls (-244.75,16.31) and (-248.98,24.48) .. (-255.36,24.22)
 .. controls (-261.78,23.95) and (-270.77,20.33) .. (-274.03,21.41)
 .. controls (-277.28,22.49) and (-289.36,22.49) .. (-291.16,24.29)
 .. controls (-292.96,26.08) and (-298.16,28.41) .. (-294.04,34.54)
 .. controls (-289.91,40.67) and (-277.50,48.96) .. (-273.90,50.58)
 .. controls (-270.29,52.20) and (-251.55,63.35) .. (-248.49,65.15)
 .. controls (-245.42,66.94) and (-237.31,68.73) .. (-234.60,69.09)
 .. controls (-231.89,69.44) and (-222.52,76.99) .. (-220.53,76.98)
 .. controls (-218.55,76.98) and (-209.53,81.65) .. (-207.73,82.01)
 .. controls (-205.93,82.37) and (-203.41,79.85) .. (-201.43,81.64)
 .. controls (-199.44,83.44) and (-192.59,90.45) .. (-189.89,90.45)
 .. controls (-187.19,90.45) and (-183.95,89.91) .. (-179.27,90.10)
 .. controls (-174.60,90.28) and (-158.58,95.86) .. (-155.87,98.20)
 .. controls (-153.17,100.54) and (-146.69,103.23) .. (-145.43,104.85)
 .. controls (-144.16,106.47) and (-144.70,107.91) .. (-144.88,111.87)
 .. controls (-145.06,115.83) and (-146.33,121.96) .. (-144.71,127.36)
 .. controls (-143.08,132.76) and (-137.15,146.26) .. (-132.29,148.78)
 .. controls (-127.44,151.31) and (-116.64,154.01) .. (-114.30,154.01)
 .. controls (-111.96,154.01) and (-108.73,152.22) .. (-108.01,150.60)
 .. controls (-107.29,148.98) and (-106.21,144.66) .. (-104.59,147.54)
 .. controls (-102.97,150.42) and (-97.57,153.84) .. (-95.77,158.34)
 .. controls (-93.97,162.84) and (-87.85,171.48) .. (-83.72,174.72)
 .. controls (-79.58,177.96) and (-68.41,191.82) .. (-66.43,194.16)
 .. controls (-64.45,196.49) and (-49.85,209.97) .. (-47.51,209.97)
 .. controls (-45.17,209.97) and (-36.35,210.34) .. (-30.06,209.80)
 .. controls (-23.76,209.27) and (-15.49,208.91) .. (-11.71,207.66)
 .. controls (-7.93,206.40) and (-2.35,206.58) .. (-1.45,202.26)
 .. controls (-0.55,197.94) and (0.17,194.70) .. (-5.95,187.14)
 .. controls (-12.08,179.59) and (-12.26,178.15) .. (-16.04,173.11)
 .. controls (-19.82,168.08) and (-23.43,164.12) .. (-27.21,159.62)
 .. controls (-30.99,155.12) and (-32.97,152.78) .. (-32.97,152.78)
));
drawoptions();
p_rimstonepool((-255.40,8.76),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-265.54,4.81),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-276.75,0.52),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-289.39,-3.74),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-288.68,-13.50),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-276.40,-11.00),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-266.31,-9.50),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-257.01,-7.40),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-296.51,-26.67),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-283.35,-26.80),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-272.29,-24.84),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-257.71,-23.92),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-306.30,-50.65),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-293.65,-49.48),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-281.82,-47.74),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-297.87,-40.78),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-275.30,-36.69),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-272.93,-47.36),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-286.71,-38.13),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-263.03,-48.42),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-254.84,-47.66),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-266.75,-35.93),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-254.26,-34.28),35.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-344.77,-189.88),334.0,1.00,(0,0));
drawoptions();
p_gradient((-284.10,-177.77),15.2,1.00,(0,0));
drawoptions();
p_gradient((-302.87,-161.21),346.1,1.00,(0,0));
drawoptions();
p_gradient((-276.30,-154.76),30.4,1.00,(0,0));
drawoptions();
p_gradient((-191.34,110.62),229.3,1.00,(0,0));
drawoptions();
p_gradient((-205.74,96.94),273.5,1.00,(0,0));
drawoptions();
p_gradient((-120.05,167.50),127.7,1.00,(0,0));
drawoptions();
p_airdraught((-139.85,149.86),321.4,1.00,(0,0));
drawoptions();
p_claychoke((-36.22,134.79),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-85.16,153.49),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-72.20,167.89),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-60.32,179.76),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-79.75,230.52),0.0,1.00,(0,0));
drawoptions();
p_curtain((-104.96,217.20),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((30.07,185.87),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((47.35,187.67),0.0,1.00,(0,0));
drawoptions();
p_stalactites((91.27,186.23),0.0,1.00,(0,0));
drawoptions();
p_stalactites((68.94,234.11),0.0,1.00,(0,0));
drawoptions();
p_stalactites((30.43,250.66),0.0,1.00,(0,0));
drawoptions();
p_curtain((-138.05,122.14),0.0,1.00,(0,0));
drawoptions();
p_rimstonepool((-336.63,-180.15),336.0,1.00,(0,0));
drawoptions();
p_rimstonepool((-328.78,-183.38),340.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-315.63,-183.17),345.0,1.00,(0,0));
drawoptions();
p_rimstonepool((-327.50,-166.16),339.4,1.00,(0,0));
drawoptions();
p_rimstonepool((-315.81,-170.91),347.9,1.00,(0,0));
drawoptions();
p_rimstonepool((-304.20,-176.49),5.9,1.00,(0,0));
drawoptions();
p_rimstonepool((-322.71,-189.84),342.7,1.00,(0,0));
drawoptions();
p_rimstonepool((-306.20,-189.34),3.6,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-20.38,145.23)
 .. controls (-16.41,148.83) and (9.17,183.72) .. (14.94,189.12)
 .. controls (20.71,194.51) and (33.31,208.54) .. (45.20,199.54)
 .. controls (57.07,190.55) and (81.91,184.80) .. (84.43,184.08)
 .. controls (86.95,183.35) and (102.78,179.74) .. (95.59,171.84)
 .. controls (91.98,167.88) and (82.26,166.81) .. (76.50,165.37)
 .. controls (70.73,163.93) and (57.77,163.21) .. (61.73,157.10)
 .. controls (65.69,150.98) and (68.56,140.91) .. (75.04,136.23)
 .. controls (81.51,131.56) and (98.80,130.12) .. (105.99,127.96)
 .. controls (113.19,125.80) and (141.99,120.76) .. (147.03,117.16)
 .. controls (152.07,113.56) and (171.15,107.45) .. (183.03,109.25)
 .. controls (194.91,111.04) and (228.41,134.07) .. (236.69,140.18)
 .. controls (244.97,146.30) and (273.78,168.25) .. (281.34,175.45)
 .. controls (288.90,182.65) and (312.66,185.88) .. (318.07,189.48)
 .. controls (323.47,193.08) and (348.32,214.30) .. (348.32,214.30)
 -- (353.00,216.10)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-173.16,133.13)
 .. controls (-176.76,131.15) and (-178.02,128.99) .. (-183.60,127.37)
 .. controls (-189.18,125.75) and (-194.04,120.52) .. (-199.79,118.53)
 .. controls (-205.55,116.55) and (-215.28,112.96) .. (-218.70,111.34)
 .. controls (-222.13,109.73) and (-236.02,104.35) .. (-245.22,98.25)
 .. controls (-254.42,92.14) and (-268.13,86.58) .. (-273.00,82.45)
 .. controls (-277.86,78.32) and (-290.83,71.66) .. (-294.07,68.06)
 .. controls (-297.31,64.45) and (-303.42,58.68) .. (-307.19,55.98)
 .. controls (-310.96,53.27) and (-319.75,48.93) .. (-324.96,46.40)
 .. controls (-330.17,43.87) and (-337.01,41.53) .. (-340.80,39.19)
 .. controls (-344.58,36.86) and (-350.18,29.49) .. (-349.27,24.80)
 .. controls (-348.37,20.12) and (-347.29,17.78) .. (-343.14,12.19)
 .. controls (-339.01,6.62) and (-339.93,3.57) .. (-334.16,1.95)
 .. controls (-328.41,0.33) and (-323.90,0.69) .. (-320.12,1.77)
 .. controls (-316.34,2.85) and (-308.80,2.32) .. (-306.11,1.25)
 .. controls (-303.42,0.18) and (-300.73,-1.60) .. (-300.19,-3.74)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-164.33,132.94)
 .. controls (-164.69,131.50) and (-158.57,130.78) .. (-157.67,125.74)
 .. controls (-156.77,120.70) and (-151.18,113.85) .. (-156.76,111.33)
 .. controls (-162.35,108.82) and (-168.48,107.38) .. (-171.54,105.58)
 .. controls (-174.60,103.78) and (-179.28,103.96) .. (-179.28,108.64)
 .. controls (-179.28,113.33) and (-177.30,118.55) .. (-176.58,121.07)
 .. controls (-175.86,123.59) and (-172.22,128.19) .. (-169.73,130.42)
 .. controls (-166.13,133.66) and (-166.13,132.40) .. (-169.73,130.42)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((333.55,285.22)
 .. controls (333.55,285.22) and (322.57,280.54) .. (313.57,280.55)
 .. controls (304.57,280.55) and (294.31,278.76) .. (284.41,278.76)
 .. controls (274.50,278.77) and (277.56,276.78) .. (267.48,276.25)
 .. controls (257.40,275.71) and (244.80,276.43) .. (238.31,277.52)
 .. controls (231.83,278.60) and (220.13,278.60) .. (213.11,279.14)
 .. controls (206.09,279.68) and (193.30,278.06) .. (185.38,283.29)
 .. controls (177.46,288.51) and (178.54,297.51) .. (167.92,296.79)
 .. controls (157.29,296.07) and (150.27,294.63) .. (144.33,292.47)
 .. controls (138.39,290.31) and (121.65,289.23) .. (114.10,281.48)
 .. controls (106.54,273.74) and (102.94,269.78) .. (104.93,259.87)
 .. controls (106.91,249.97) and (107.10,240.79) .. (107.28,235.93)
 .. controls (107.46,231.06) and (105.31,218.28) .. (104.05,213.05)
 .. controls (102.80,207.83) and (102.62,199.01) .. (101.36,197.75)
 .. controls (100.10,196.49) and (99.38,193.97) .. (95.42,198.65)
 .. controls (91.45,203.33) and (88.75,211.26) .. (85.51,213.78)
 .. controls (82.27,216.30) and (73.44,220.44) .. (67.68,223.67)
 .. controls (61.93,226.91) and (52.39,232.66) .. (50.23,236.08)
 .. controls (48.07,239.50) and (45.73,247.96) .. (40.15,245.98)
 .. controls (34.57,244.00) and (12.06,240.05) .. (0.17,237.90)
 .. controls (-11.71,235.74) and (-35.82,234.46) .. (-41.76,231.94)
 .. controls (-47.69,229.41) and (-51.47,231.76) .. (-57.60,226.72)
 .. controls (-63.72,221.68) and (-89.12,211.26) .. (-94.87,205.50)
 .. controls (-100.63,199.73) and (-116.27,193.24) .. (-117.71,190.71)
 .. controls (-119.14,188.19) and (-122.02,186.03) .. (-124.54,185.85)
 .. controls (-127.06,185.67) and (-127.78,184.59) .. (-129.58,179.73)
 .. controls (-131.39,174.87) and (-145.07,157.06) .. (-146.69,152.92)
 .. controls (-148.31,148.78) and (-151.36,142.65) .. (-154.06,140.67)
 .. controls (-156.76,138.69) and (-163.25,138.70) .. (-163.61,137.26)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-299.69,-14.45)
 .. controls (-303.00,-19.79) and (-302.16,-25.01) .. (-306.23,-32.39)
 .. controls (-310.32,-39.79) and (-315.45,-46.50) .. (-316.66,-50.85)
 .. controls (-317.88,-55.23) and (-319.64,-61.69) .. (-319.86,-64.77)
 .. controls (-320.09,-67.88) and (-321.17,-80.86) .. (-321.12,-86.21)
 .. controls (-321.06,-91.60) and (-320.23,-97.22) .. (-319.51,-103.24)
 .. controls (-318.79,-109.30) and (-319.01,-111.70) .. (-318.29,-113.54)
 .. controls (-317.56,-115.38) and (-317.18,-114.27) .. (-316.26,-118.88)
 .. controls (-315.35,-123.48) and (-315.32,-124.21) .. (-317.60,-124.97)
 .. controls (-319.87,-125.73) and (-321.93,-125.03) .. (-322.96,-131.33)
 .. controls (-323.99,-137.66) and (-323.25,-144.60) .. (-325.50,-149.46)
 .. controls (-327.77,-154.38) and (-337.17,-165.31) .. (-341.92,-172.33)
 .. controls (-346.69,-179.39) and (-349.87,-179.98) .. (-354.65,-184.08)
 .. controls (-359.33,-188.09) and (-360.63,-190.17) .. (-363.78,-191.50)
 .. controls (-366.89,-192.80) and (-365.25,-193.28) .. (-371.10,-192.42)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-299.69,-14.45)
 -- (-306.03,-17.44)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-300.19,-3.74)
 -- (-303.44,-6.59)
));
endfig;
beginfig(12);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char53 \mainfont{} etex,(-341.64,-126.37),0.0,0);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char84 \char104 \char101 \ \char67 \char97 \char116 \char104 \char101 \char100 \char114 \char97 \char108 \mainfont{} etex,(-381.09,-298.56),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char104 \char108 \char63 \mainfont{} etex,(-326.30,-21.78),0.0,0);
drawoptions();
p_label(btex \thremark \thnormalsize \thfb\char116 \char116 \mainfont{} etex,(-173.70,146.27),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char51 \mainfont{} etex,(-148.50,179.03),0.0,0);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char72 \char101 \char108 \char109 \char39 \char115 \ \char68 \char101 \char101 \char112 \mainfont{} etex,(386.80,131.93),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char51 \mainfont{} etex,(-182.34,77.50),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char104 \char108 \char63 \mainfont{} etex,(-243.77,-91.37),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char56 \mainfont{} etex,(426.05,215.06),0.0,0);
endfig;
background:=(0.25000,1.00000,0.73000);
def_transparent_rgb(tr_bg, 0.25000, 1.00000, 0.73000);
current_scrap := "romeoSP2@romeo_entrance.romeo";
ATTR__scrap := "romeoSP2";
beginfig(13);
current_src := "Romeo_entrance.th2 [2432]";
string area_border[];
area_border[1] := "l440-15428-38518";
drawoptions();
a_sand(buildcycle(((504.05,194.17)
 .. controls (504.05,194.17) and (497.93,129.01) .. (597.65,127.93)
 .. controls (697.37,126.85) and (762.53,197.05) .. (762.53,197.05)
 -- (858.28,324.85)
 -- (799.62,502.69)
 -- (796.02,528.25)
 -- (720.06,523.57)
 -- (756.77,328.09)
 -- (552.65,247.81)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2416]";
string area_border[];
area_border[1] := "l442-13814-41308";
drawoptions();
a_sand(buildcycle(((486.78,743.16)
 .. controls (486.78,743.16) and (521.70,816.24) .. (548.34,822.00)
 .. controls (574.98,827.76) and (395.70,826.68) .. (395.70,826.68)
 -- (236.58,865.93)
 .. controls (236.58,865.93) and (223.62,843.61) .. (235.14,819.85)
 .. controls (246.66,796.09) and (452.58,756.12) .. (456.90,770.16)
 .. controls (461.22,784.20) and (486.78,743.16) .. cycle
)));
current_src := "Romeo_entrance.th2 [2401]";
string area_border[];
area_border[1] := "l444-11858-41918";
drawoptions();
a_sand(buildcycle(((43.63,966.01)
 .. controls (43.63,966.01) and (5.11,907.69) .. (0.07,884.65)
 .. controls (-4.97,861.61) and (85.39,851.53) .. (85.39,851.53)
 -- (190.50,808.69)
 .. controls (190.50,808.69) and (191.58,854.41) .. (166.38,891.85)
 .. controls (141.19,929.29) and (43.63,966.01) .. cycle
)));
current_src := "Romeo_entrance.th2 [2167]";
string area_border[];
area_border[1] := "l201-13104-32510";
area_border[2] := "l434-12712-32640";
drawoptions();
a_sand(buildcycle(((331.39,-748.30)
 .. controls (332.47,-764.68) and (332.47,-781.42) .. (332.83,-786.64)
),
((331.39,-748.30)
 -- (286.93,-728.50)
 -- (201.97,-741.81)
 -- (163.45,-782.49)
 -- (117.02,-785.37)
 -- (102.62,-918.21)
 -- (-55.78,-1164.08)
 -- (42.86,-1201.16)
 -- (149.78,-918.21)
 -- (197.66,-867.45)
 -- (213.13,-827.85)
 -- (283.69,-851.25)
 -- (332.83,-786.64)
)));
current_src := "Romeo_entrance.th2 [2141]";
string area_border[];
area_border[1] := "l377-7298-41230";
area_border[2] := "l379-7348-41144";
area_border[3] := "l375-7304-40976";
drawoptions();
a_water(buildcycle(((-707.33,810.89)
 .. controls (-732.17,827.09) and (-735.41,770.57) .. (-735.41,770.57)
),
((-696.53,769.49)
 -- (-707.33,810.89)
),
((-696.53,769.49)
 .. controls (-696.53,769.49) and (-717.05,764.09) .. (-735.41,770.57)
)));
current_src := "Romeo_entrance.th2 [2048]";
string area_border[];
area_border[1] := "l356-7470-41672";
area_border[2] := "l358-7410-41570";
area_border[3] := "l355-7502-41298";
area_border[4] := "l357-7592-41434";
drawoptions();
a_water(buildcycle(((-661.97,893.33)
 .. controls (-661.97,893.33) and (-682.85,895.49) .. (-694.73,890.45)
),
((-690.41,822.05)
 -- (-694.73,890.45)
),
((-660.53,826.37)
 .. controls (-660.53,826.37) and (-673.49,827.09) .. (-690.41,822.05)
),
((-661.97,893.33)
 -- (-660.53,826.37)
)));
current_src := "Romeo_entrance.th2 [2005]";
string area_border[];
area_border[1] := "l362-7548-41836";
area_border[2] := "l363-7344-41730";
area_border[3] := "l360-7378-41944";
area_border[4] := "l366-7648-42188";
area_border[5] := "l364-8542-42664";
area_border[6] := "l365-8550-42576";
drawoptions();
a_water(buildcycle(((-692.93,895.85)
 .. controls (-692.93,895.85) and (-683.08,894.86) .. (-670.97,897.65)
 .. controls (-666.29,898.73) and (-677.37,920.80) .. (-664.49,923.21)
 .. controls (-660.19,924.02) and (-660.53,946.97) .. (-660.53,946.97)
),
((-692.93,895.85)
 .. controls (-692.93,895.85) and (-714.17,904.13) .. (-705.53,915.65)
),
((-705.53,915.65)
 .. controls (-705.53,915.65) and (-709.13,947.69) .. (-673.13,961.37)
 .. controls (-661.84,965.66) and (-659.09,973.61) .. (-662.51,970.19)
),
((-509.69,1072.96)
 .. controls (-509.69,1072.96) and (-611.57,1039.49) .. (-662.51,970.19)
),
((-509.69,1072.96)
 .. controls (-509.69,1072.96) and (-498.17,1075.84) .. (-493.49,1074.04)
 .. controls (-488.81,1072.24) and (-485.57,1067.56) .. (-481.43,1065.22)
),
((-481.43,1065.22)
 .. controls (-481.43,1065.22) and (-522.29,993.04) .. (-660.53,946.97)
)));
current_src := "Romeo_entrance.th2 [1979]";
string area_border[];
area_border[1] := "l369-9058-43258";
area_border[2] := "l370-8868-43178";
area_border[3] := "l368-8578-42746";
drawoptions();
a_water(buildcycle(((-476.93,1068.64)
 .. controls (-476.93,1068.64) and (-353.81,1113.63) .. (-352.73,1124.79)
 .. controls (-351.65,1135.95) and (-351.65,1133.07) .. (-369.29,1162.95)
 .. controls (-386.92,1192.83) and (-416.80,1170.87) .. (-416.80,1170.87)
),
((-416.80,1170.87)
 .. controls (-459.64,1151.80) and (-477.65,1102.48) .. (-477.65,1102.48)
),
((-477.65,1102.48)
 .. controls (-477.65,1102.48) and (-491.33,1080.88) .. (-476.93,1068.64)
)));
current_src := "Romeo_entrance.th2 [1959]";
string area_border[];
area_border[1] := "l373-9272-43312";
drawoptions();
a_blocks(buildcycle(((-376.85,1175.19)
 -- (-354.53,1140.27)
 -- (-348.41,1140.09)
 -- (-328.97,1180.95)
 -- (-346.60,1194.99)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1912]";
string area_border[];
area_border[1] := "l327-6804-40862";
area_border[2] := "l329-6908-40900";
area_border[3] := "l330-6964-40858";
area_border[4] := "l328-6956-40620";
drawoptions();
a_flowstone(buildcycle(((-789.77,755.10)
 .. controls (-789.77,755.10) and (-815.69,750.42) .. (-818.21,700.38)
),
((-789.77,755.10)
 -- (-775.72,752.94)
),
((-763.12,708.66)
 .. controls (-764.56,710.82) and (-775.72,752.94) .. (-775.72,752.94)
),
((-818.21,700.38)
 .. controls (-818.21,700.38) and (-773.92,697.14) .. (-763.12,708.66)
)));
current_src := "Romeo_entrance.th2 [1900]";
string area_border[];
area_border[1] := "l332-6706-40886";
drawoptions();
a_blocks(buildcycle(((-852.77,749.34)
 -- (-835.49,705.42)
 -- (-822.89,705.78)
 -- (-808.49,752.22)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1884]";
string area_border[];
area_border[1] := "l283-7142-40660";
area_border[2] := "l298-7002-40710";
drawoptions();
a_water(buildcycle(((-764.93,714.78)
 .. controls (-750.17,712.98) and (-748.43,707.76) .. (-732.89,713.34)
 .. controls (-718.85,718.38) and (-730.00,743.21) .. (-747.28,731.33)
 .. controls (-751.14,728.68) and (-757.00,732.78) .. (-768.53,724.86)
),
((-768.53,724.86)
 -- (-764.93,714.78)
)));
ATTR__id := "l434-12712-32640";
ATTR__height := -1;
drawoptions();
l_border_invisible(((331.39,-748.30)
 -- (286.93,-728.50)
 -- (201.97,-741.81)
 -- (163.45,-782.49)
 -- (117.02,-785.37)
 -- (102.62,-918.21)
 -- (-55.78,-1164.08)
 -- (42.86,-1201.16)
 -- (149.78,-918.21)
 -- (197.66,-867.45)
 -- (213.13,-827.85)
 -- (283.69,-851.25)
 -- (332.83,-786.64)
));
ATTR__id := "l440-15428-38518";
ATTR__height := -1;
drawoptions();
l_border_invisible(((504.05,194.17)
 .. controls (504.05,194.17) and (497.93,129.01) .. (597.65,127.93)
 .. controls (697.37,126.85) and (762.53,197.05) .. (762.53,197.05)
 -- (858.28,324.85)
 -- (799.62,502.69)
 -- (796.02,528.25)
 -- (720.06,523.57)
 -- (756.77,328.09)
 -- (552.65,247.81)
 -- cycle
));
ATTR__id := "l442-13814-41308";
ATTR__height := -1;
drawoptions();
l_border_invisible(((486.78,743.16)
 .. controls (486.78,743.16) and (521.70,816.24) .. (548.34,822.00)
 .. controls (574.98,827.76) and (395.70,826.68) .. (395.70,826.68)
 -- (236.58,865.93)
 .. controls (236.58,865.93) and (223.62,843.61) .. (235.14,819.85)
 .. controls (246.66,796.09) and (452.58,756.12) .. (456.90,770.16)
 .. controls (461.22,784.20) and (486.78,743.16) .. cycle
));
ATTR__id := "l444-11858-41918";
ATTR__height := -1;
drawoptions();
l_border_invisible(((43.63,966.01)
 .. controls (43.63,966.01) and (5.11,907.69) .. (0.07,884.65)
 .. controls (-4.97,861.61) and (85.39,851.53) .. (85.39,851.53)
 -- (190.50,808.69)
 .. controls (190.50,808.69) and (191.58,854.41) .. (166.38,891.85)
 .. controls (141.19,929.29) and (43.63,966.01) .. cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((24.55,970.33)
 .. controls (-25.13,948.73) and (-35.93,980.05) .. (-35.93,980.05)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-39.53,949.09)
 .. controls (-39.53,949.09) and (-0.65,935.05) .. (30.31,955.21)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((-348.41,1134.87)
 .. controls (-348.41,1134.87) and (-339.05,1183.47) .. (-315.64,1188.51)
));
ATTR__height := -1;
drawoptions();
l_pit(((469.09,-725.61)
 .. controls (469.09,-725.61) and (431.28,-738.76) .. (459.73,-740.37)
 .. controls (478.81,-741.45) and (499.73,-714.55) .. (481.33,-720.21)
 .. controls (467.29,-724.53) and (469.09,-725.61) .. cycle
));
ATTR__id := "l375-7304-40976";
ATTR__height := -1;
drawoptions();
l_flowstone(((-696.53,769.49)
 .. controls (-696.53,769.49) and (-717.05,764.09) .. (-735.41,770.57)
));
ATTR__id := "l377-7298-41230";
ATTR__height := -1;
drawoptions();
l_flowstone(((-707.33,810.89)
 .. controls (-732.17,827.09) and (-735.41,770.57) .. (-735.41,770.57)
));
ATTR__id := "l379-7348-41144";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-696.53,769.49)
 -- (-707.33,810.89)
));
ATTR__id := "l201-13104-32510";
ATTR__height := -1;
drawoptions();
l_pit(((331.39,-748.30)
 .. controls (332.47,-764.68) and (332.47,-781.42) .. (332.83,-786.64)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-661.25,742.85)
 .. controls (-664.13,742.13) and (-680.33,751.13) .. (-682.13,751.13)
 .. controls (-696.53,751.13) and (-707.33,810.89) .. (-707.33,810.89)
));
ATTR__id := "l356-7470-41672";
ATTR__height := -1;
drawoptions();
l_flowstone(((-661.97,893.33)
 .. controls (-661.97,893.33) and (-682.85,895.49) .. (-694.73,890.45)
));
ATTR__id := "l358-7410-41570";
ATTR__height := -1;
drawoptions();
l_flowstone(((-690.41,822.05)
 -- (-694.73,890.45)
));
ATTR__id := "l360-7378-41944";
ATTR__height := -1;
drawoptions();
l_flowstone(((-705.53,915.65)
 .. controls (-705.53,915.65) and (-709.13,947.69) .. (-673.13,961.37)
 .. controls (-661.84,965.66) and (-659.09,973.61) .. (-662.51,970.19)
));
ATTR__id := "l362-7548-41836";
ATTR__height := -1;
drawoptions();
l_flowstone(((-692.93,895.85)
 .. controls (-692.93,895.85) and (-683.08,894.86) .. (-670.97,897.65)
 .. controls (-666.29,898.73) and (-677.37,920.80) .. (-664.49,923.21)
 .. controls (-660.19,924.02) and (-660.53,946.97) .. (-660.53,946.97)
));
ATTR__id := "l363-7344-41730";
ATTR__height := -1;
drawoptions();
l_border_visible(((-692.93,895.85)
 .. controls (-692.93,895.85) and (-714.17,904.13) .. (-705.53,915.65)
));
ATTR__id := "l364-8542-42664";
ATTR__height := -1;
drawoptions();
l_border_visible(((-509.69,1072.96)
 .. controls (-509.69,1072.96) and (-498.17,1075.84) .. (-493.49,1074.04)
 .. controls (-488.81,1072.24) and (-485.57,1067.56) .. (-481.43,1065.22)
));
ATTR__id := "l366-7648-42188";
ATTR__height := -1;
drawoptions();
l_border_visible(((-509.69,1072.96)
 .. controls (-509.69,1072.96) and (-611.57,1039.49) .. (-662.51,970.19)
));
ATTR__id := "l368-8578-42746";
ATTR__height := -1;
drawoptions();
l_border_visible(((-477.65,1102.48)
 .. controls (-477.65,1102.48) and (-491.33,1080.88) .. (-476.93,1068.64)
));
ATTR__id := "l369-9058-43258";
ATTR__height := -1;
drawoptions();
l_border_visible(((-476.93,1068.64)
 .. controls (-476.93,1068.64) and (-353.81,1113.63) .. (-352.73,1124.79)
 .. controls (-351.65,1135.95) and (-351.65,1133.07) .. (-369.29,1162.95)
 .. controls (-386.92,1192.83) and (-416.80,1170.87) .. (-416.80,1170.87)
));
ATTR__id := "l370-8868-43178";
ATTR__height := -1;
drawoptions();
l_border_visible(((-416.80,1170.87)
 .. controls (-459.64,1151.80) and (-477.65,1102.48) .. (-477.65,1102.48)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-349.48,1193.91)
 .. controls (-361.00,1196.07) and (-364.25,1188.51) .. (-372.53,1183.11)
 .. controls (-380.81,1177.71) and (-398.44,1181.31) .. (-398.44,1181.31)
));
ATTR__id := "l373-9272-43312";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-376.85,1175.19)
 -- (-354.53,1140.27)
 -- (-348.41,1140.09)
 -- (-328.97,1180.95)
 -- (-346.60,1194.99)
 -- cycle
));
ATTR__id := "l365-8550-42576";
ATTR__height := -1;
drawoptions();
l_border_visible(((-481.43,1065.22)
 .. controls (-481.43,1065.22) and (-522.29,993.04) .. (-660.53,946.97)
));
ATTR__id := "l357-7592-41434";
ATTR__height := -1;
drawoptions();
l_flowstone(((-661.97,893.33)
 -- (-660.53,826.37)
));
ATTR__id := "l355-7502-41298";
ATTR__height := -1;
drawoptions();
l_flowstone(((-660.53,826.37)
 .. controls (-660.53,826.37) and (-673.49,827.09) .. (-690.41,822.05)
));
ATTR__id := "l327-6804-40862";
ATTR__height := -1;
drawoptions();
l_border_visible(((-789.77,755.10)
 .. controls (-789.77,755.10) and (-815.69,750.42) .. (-818.21,700.38)
));
ATTR__id := "l328-6956-40620";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-818.21,700.38)
 .. controls (-818.21,700.38) and (-773.92,697.14) .. (-763.12,708.66)
));
ATTR__id := "l329-6908-40900";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-789.77,755.10)
 -- (-775.72,752.94)
));
ATTR__id := "l330-6964-40858";
ATTR__height := -1;
drawoptions();
l_pit(((-763.12,708.66)
 .. controls (-764.56,710.82) and (-775.72,752.94) .. (-775.72,752.94)
));
ATTR__id := "l332-6706-40886";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-852.77,749.34)
 -- (-835.49,705.42)
 -- (-822.89,705.78)
 -- (-808.49,752.22)
 -- cycle
));
ATTR__id := "l298-7002-40710";
ATTR__height := -1;
drawoptions();
l_border_visible(((-768.53,724.86)
 -- (-764.93,714.78)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_floorstep(((-744.04,756.53)
 .. controls (-744.40,754.73) and (-773.56,750.78) .. (-789.77,755.10)
 .. controls (-805.97,759.42) and (-862.13,754.74) .. (-862.13,754.74)
));
ATTR__id := "l283-7142-40660";
ATTR__height := -1;
drawoptions();
l_border_visible(((-764.93,714.78)
 .. controls (-750.17,712.98) and (-748.43,707.76) .. (-732.89,713.34)
 .. controls (-718.85,718.38) and (-730.00,743.21) .. (-747.28,731.33)
 .. controls (-751.14,728.68) and (-757.00,732.78) .. (-768.53,724.86)
));
ATTR__id := "";
drawoptions();
p_guano((40.70,-1146.44),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_flowstone(((764.70,664.32)
 .. controls (746.70,673.32) and (751.02,688.08) .. (751.02,688.08)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((791.70,666.84)
 .. controls (765.78,668.28) and (769.74,687.36) .. (769.74,687.36)
));
endfig;
beginfig(14);
draw_upscrap(1)(1,((43.94,-1178.48)
 .. controls (43.94,-1178.48) and (59.78,-1145.54) .. (62.12,-1139.24)
 .. controls (64.46,-1132.94) and (79.04,-1094.78) .. (79.94,-1091.54)
 .. controls (80.84,-1088.30) and (88.40,-1064.90) .. (89.84,-1061.66)
 .. controls (91.28,-1058.42) and (94.16,-1059.32) .. (97.22,-1053.74)
 .. controls (100.28,-1048.16) and (107.84,-1018.46) .. (108.92,-1016.30)
 .. controls (110.00,-1014.15) and (119.36,-983.73) .. (119.54,-979.41)
 .. controls (119.72,-975.09) and (131.24,-949.89) .. (132.14,-945.75)
 .. controls (133.04,-941.61) and (132.86,-930.81) .. (132.50,-928.83)
 .. controls (132.14,-926.85) and (130.88,-917.85) .. (136.64,-912.63)
 .. controls (142.40,-907.41) and (154.46,-892.83) .. (156.44,-890.49)
 .. controls (158.42,-888.15) and (175.16,-872.67) .. (177.32,-871.05)
 .. controls (179.48,-869.43) and (197.84,-849.81) .. (198.56,-848.01)
 .. controls (199.28,-846.21) and (203.78,-842.07) .. (198.92,-832.71)
 .. controls (194.06,-823.35) and (191.36,-818.31) .. (191.36,-816.87)
 .. controls (191.35,-815.43) and (189.01,-811.29) .. (194.41,-810.57)
 .. controls (199.81,-809.85) and (215.29,-810.03) .. (218.53,-812.73)
 .. controls (221.77,-815.43) and (239.05,-830.55) .. (240.49,-832.35)
 .. controls (241.93,-834.15) and (258.85,-843.51) .. (264.43,-841.89)
 .. controls (270.01,-840.27) and (282.79,-842.79) .. (291.97,-828.39)
 .. controls (301.15,-814.00) and (308.89,-811.12) .. (311.77,-805.36)
 .. controls (314.65,-799.60) and (321.85,-787.72) .. (326.89,-787.36)
 .. controls (331.93,-787.00) and (340.75,-784.30) .. (350.11,-787.54)
 .. controls (359.47,-790.78) and (377.29,-787.72) .. (385.93,-796.00)
 .. controls (394.57,-804.28) and (409.69,-813.64) .. (413.65,-814.18)
 .. controls (417.61,-814.72) and (435.26,-815.98) .. (439.76,-813.28)
 .. controls (444.26,-810.58) and (479.90,-785.37) .. (484.40,-780.69)
 .. controls (488.90,-776.01) and (507.79,-760.35) .. (510.31,-757.65)
 .. controls (512.83,-754.95) and (534.25,-739.29) .. (539.29,-736.05)
 .. controls (544.33,-732.81) and (580.87,-711.57) .. (586.27,-705.99)
 .. controls (591.67,-700.41) and (627.32,-675.75) .. (632.54,-672.51)
 .. controls (637.76,-669.27) and (652.70,-656.31) .. (654.68,-646.77)
 .. controls (656.66,-637.23) and (655.58,-630.39) .. (654.32,-628.05)
 .. controls (653.06,-625.71) and (650.72,-617.07) .. (653.96,-611.68)
 .. controls (657.20,-606.28) and (663.32,-599.26) .. (665.66,-596.20)
 .. controls (668.00,-593.14) and (673.94,-581.44) .. (674.84,-578.92)
 .. controls (675.74,-576.40) and (684.38,-551.20) .. (686.00,-545.44)
 .. controls (687.62,-539.68) and (686.90,-531.04) .. (686.72,-527.26)
 .. controls (686.54,-523.48) and (687.98,-517.54) .. (689.78,-513.76)
 .. controls (691.58,-509.98) and (698.24,-495.04) .. (699.68,-491.80)
 .. controls (701.12,-488.56) and (702.74,-477.04) .. (702.74,-473.98)
 .. controls (702.74,-470.92) and (705.98,-448.24) .. (705.80,-441.76)
 .. controls (705.62,-435.28) and (709.40,-418.00) .. (709.76,-412.06)
 .. controls (710.12,-406.12) and (715.70,-381.10) .. (716.96,-377.15)
 .. controls (718.23,-373.19) and (718.41,-361.49) .. (717.51,-356.81)
 .. controls (716.61,-352.13) and (714.45,-326.57) .. (712.83,-322.25)
 .. controls (711.21,-317.93) and (711.03,-305.87) .. (712.11,-299.39)
 .. controls (713.19,-292.91) and (712.29,-281.03) .. (710.85,-276.35)
 .. controls (709.41,-271.67) and (706.89,-256.01) .. (705.09,-252.23)
 .. controls (703.29,-248.45) and (699.51,-241.79) .. (695.91,-235.49)
 .. controls (692.31,-229.19) and (684.03,-216.77) .. (681.15,-214.43)
 .. controls (678.27,-212.09) and (677.01,-214.25) .. (672.51,-211.55)
 .. controls (668.01,-208.85) and (664.59,-210.29) .. (661.17,-201.11)
 .. controls (657.75,-191.93) and (655.77,-183.83) .. (653.61,-179.69)
 .. controls (651.45,-175.55) and (649.11,-168.89) .. (647.85,-166.73)
 .. controls (646.59,-164.57) and (634.89,-144.77) .. (633.45,-142.97)
 .. controls (632.01,-141.16) and (614.92,-128.02) .. (611.32,-125.32)
 .. controls (607.72,-122.62) and (599.44,-117.94) .. (593.86,-111.82)
 .. controls (588.28,-105.70) and (582.52,-100.84) .. (582.52,-95.44)
 .. controls (582.52,-90.04) and (579.82,-81.04) .. (578.92,-77.44)
 .. controls (578.02,-73.84) and (568.48,-57.82) .. (565.96,-52.60)
 .. controls (563.44,-47.38) and (562.90,-41.62) .. (560.02,-37.49)
 .. controls (557.14,-33.35) and (554.08,-29.75) .. (553.54,-29.21)
 .. controls (553.00,-28.67) and (547.06,-27.59) .. (547.42,-20.93)
 .. controls (547.78,-14.27) and (551.38,-11.57) .. (551.92,-10.13)
 .. controls (552.46,-8.69) and (558.94,10.03) .. (557.32,20.83)
 .. controls (555.70,31.63) and (553.00,48.37) .. (552.10,52.51)
 .. controls (551.20,56.65) and (546.70,77.34) .. (545.99,85.98)
 .. controls (545.27,94.62) and (546.17,109.21) .. (550.13,113.17)
 .. controls (554.09,117.13) and (570.83,130.45) .. (578.93,134.05)
 .. controls (587.03,137.65) and (611.33,148.27) .. (614.03,150.25)
 .. controls (616.73,152.23) and (675.23,178.87) .. (681.53,182.65)
 .. controls (687.83,186.43) and (720.23,208.39) .. (723.47,211.09)
 .. controls (726.71,213.79) and (746.15,227.65) .. (749.21,229.09)
 .. controls (752.27,230.53) and (769.01,239.35) .. (772.07,241.87)
 .. controls (775.13,244.39) and (798.17,262.39) .. (803.38,267.07)
 .. controls (808.60,271.75) and (820.84,285.43) .. (823.00,290.29)
 .. controls (825.16,295.15) and (827.33,318.19) .. (826.61,321.07)
 .. controls (825.89,323.95) and (822.83,358.33) .. (819.77,366.97)
 .. controls (816.71,375.61) and (808.61,401.17) .. (806.99,407.83)
 .. controls (805.37,414.49) and (798.53,430.87) .. (797.99,437.53)
 .. controls (797.45,444.19) and (793.50,476.59) .. (791.34,481.81)
 .. controls (789.18,487.03) and (787.38,505.39) .. (785.58,510.61)
 .. controls (783.78,515.83) and (780.54,531.67) .. (781.80,536.17)
 .. controls (783.06,540.67) and (786.12,550.57) .. (787.92,553.63)
 .. controls (789.72,556.69) and (809.34,580.98) .. (813.12,585.84)
 .. controls (816.90,590.70) and (831.12,606.54) .. (833.46,611.04)
 .. controls (835.80,615.54) and (841.74,617.70) .. (841.20,620.22)
 .. controls (840.66,622.74) and (842.82,622.92) .. (837.06,627.96)
 .. controls (831.30,633.00) and (810.42,662.16) .. (806.64,665.40)
 .. controls (802.86,668.64) and (790.08,680.70) .. (782.16,684.48)
 .. controls (774.24,688.26) and (746.52,704.46) .. (744.36,704.82)
 .. controls (742.20,705.18) and (739.86,707.16) .. (731.58,710.22)
 .. controls (723.30,713.28) and (711.78,714.91) .. (705.48,716.53)
 .. controls (699.18,718.15) and (691.44,718.51) .. (687.84,721.39)
 .. controls (684.24,724.27) and (678.48,722.83) .. (678.66,736.15)
 .. controls (678.84,749.47) and (678.84,759.55) .. (683.16,765.31)
 .. controls (687.48,771.07) and (690.72,784.03) .. (690.54,789.79)
 .. controls (690.36,795.55) and (698.28,804.01) .. (695.58,806.17)
 .. controls (692.88,808.33) and (690.90,809.05) .. (682.44,811.03)
 .. controls (673.98,813.01) and (658.14,815.71) .. (653.46,817.15)
 .. controls (648.78,818.59) and (620.70,821.47) .. (608.82,820.38)
 .. controls (596.94,819.30) and (586.68,820.56) .. (583.98,822.00)
 .. controls (581.28,823.44) and (571.20,824.70) .. (564.36,817.86)
 .. controls (557.52,811.02) and (548.70,806.52) .. (542.22,809.04)
 .. controls (535.74,811.56) and (529.62,812.82) .. (525.66,816.24)
 .. controls (521.70,819.66) and (520.80,821.46) .. (513.60,815.88)
 .. controls (506.40,810.30) and (501.90,806.88) .. (498.12,805.08)
 .. controls (494.34,803.28) and (490.20,799.50) .. (485.88,800.40)
 .. controls (481.56,801.30) and (476.70,801.48) .. (475.62,802.92)
 .. controls (474.54,804.36) and (476.88,807.42) .. (471.48,809.40)
 .. controls (466.08,811.38) and (462.12,811.02) .. (458.70,809.04)
 .. controls (455.28,807.06) and (450.96,806.88) .. (441.60,807.60)
 .. controls (432.24,808.32) and (430.62,809.04) .. (421.80,810.30)
 .. controls (412.98,811.56) and (414.42,814.44) .. (407.40,814.80)
 .. controls (400.38,815.16) and (388.32,813.54) .. (383.28,812.64)
 .. controls (378.24,811.74) and (367.79,814.63) .. (362.57,817.33)
 .. controls (357.35,820.03) and (345.84,823.08) .. (341.34,824.70)
 .. controls (336.84,826.32) and (321.18,829.57) .. (316.86,830.83)
 .. controls (312.54,832.09) and (304.08,835.69) .. (292.92,838.03)
 .. controls (281.76,840.37) and (269.88,839.29) .. (262.32,842.71)
 .. controls (254.76,846.13) and (246.66,850.45) .. (242.52,853.15)
 .. controls (238.38,855.85) and (237.12,857.47) .. (231.36,859.27)
 .. controls (225.60,861.07) and (220.20,863.23) .. (213.18,863.95)
 .. controls (206.16,864.67) and (196.98,865.93) .. (194.10,868.45)
 .. controls (191.22,870.97) and (190.86,876.37) .. (191.04,877.99)
 .. controls (191.22,879.61) and (192.30,882.85) .. (192.30,882.85)
),
1,((178.44,887.17)
 .. controls (177.72,885.37) and (178.08,878.89) .. (173.04,876.73)
 .. controls (168.00,874.57) and (168.54,874.57) .. (161.88,877.45)
 .. controls (155.22,880.33) and (151.98,882.67) .. (148.38,886.63)
 .. controls (144.78,890.59) and (140.65,895.81) .. (138.31,898.87)
 .. controls (135.97,901.93) and (132.19,907.15) .. (128.77,909.67)
 .. controls (125.35,912.19) and (120.13,914.17) .. (116.89,916.87)
 .. controls (113.65,919.57) and (108.79,923.71) .. (105.91,925.51)
 .. controls (103.03,927.31) and (95.29,930.37) .. (93.85,930.91)
 .. controls (92.41,931.45) and (81.97,935.23) .. (80.17,936.49)
 .. controls (78.37,937.75) and (70.81,941.35) .. (68.47,942.07)
 .. controls (66.13,942.79) and (55.33,945.13) .. (48.67,948.01)
 .. controls (42.01,950.89) and (39.49,950.89) .. (34.45,954.85)
 .. controls (29.41,958.81) and (29.59,959.53) .. (27.61,963.67)
 .. controls (25.63,967.81) and (23.83,968.89) .. (24.55,973.39)
 .. controls (25.27,977.89) and (25.45,978.43) .. (26.35,979.33)
),
1,((1.69,996.43)
 .. controls (-0.11,994.81) and (-11.09,986.89) .. (-13.61,985.45)
 .. controls (-16.13,984.01) and (-29.81,978.43) .. (-35.57,978.07)
 .. controls (-41.33,977.71) and (-53.39,983.11) .. (-54.83,984.91)
 .. controls (-56.27,986.71) and (-72.83,995.17) .. (-75.35,996.79)
 .. controls (-77.87,998.41) and (-93.35,1008.31) .. (-96.23,1010.11)
 .. controls (-99.11,1011.91) and (-100.37,1015.15) .. (-102.53,1017.49)
 .. controls (-104.69,1019.83) and (-114.41,1027.03) .. (-115.85,1028.65)
 .. controls (-117.29,1030.27) and (-125.21,1039.64) .. (-127.37,1044.14)
 .. controls (-129.53,1048.64) and (-144.65,1054.40) .. (-152.21,1065.20)
 .. controls (-159.77,1076.00) and (-170.75,1082.30) .. (-173.27,1084.10)
 .. controls (-175.79,1085.90) and (-188.21,1093.82) .. (-190.73,1096.70)
 .. controls (-193.26,1099.58) and (-201.36,1106.24) .. (-204.95,1109.66)
 .. controls (-208.55,1113.08) and (-217.19,1117.04) .. (-222.59,1119.74)
 .. controls (-227.99,1122.44) and (-239.51,1127.66) .. (-243.29,1129.64)
 .. controls (-247.07,1131.62) and (-254.99,1136.12) .. (-260.03,1136.84)
 .. controls (-265.07,1137.56) and (-272.27,1140.44) .. (-276.77,1143.14)
 .. controls (-281.27,1145.84) and (-295.85,1152.51) .. (-297.11,1155.39)
 .. controls (-298.37,1158.27) and (-306.83,1167.99) .. (-309.71,1172.85)
 .. controls (-312.59,1177.71) and (-326.98,1183.65) .. (-329.14,1185.63)
 .. controls (-331.30,1187.61) and (-357.04,1196.61) .. (-360.46,1198.05)
 .. controls (-363.88,1199.49) and (-372.34,1196.25) .. (-374.86,1196.25)
 .. controls (-377.38,1196.25) and (-407.44,1175.55) .. (-409.60,1173.93)
 .. controls (-411.76,1172.31) and (-446.87,1143.16) .. (-450.29,1140.28)
 .. controls (-453.71,1137.40) and (-475.13,1105.36) .. (-477.65,1102.48)
 .. controls (-480.17,1099.60) and (-488.63,1085.92) .. (-490.43,1084.12)
 .. controls (-492.23,1082.32) and (-503.21,1075.66) .. (-509.69,1072.96)
 .. controls (-516.17,1070.26) and (-536.51,1059.28) .. (-539.93,1056.94)
 .. controls (-543.35,1054.60) and (-557.93,1047.58) .. (-561.53,1045.96)
 .. controls (-565.13,1044.34) and (-577.01,1037.86) .. (-578.99,1035.52)
 .. controls (-580.97,1033.18) and (-590.15,1024.72) .. (-594.11,1023.65)
 .. controls (-598.07,1022.57) and (-609.23,1016.99) .. (-611.39,1013.03)
 .. controls (-613.55,1009.07) and (-624.35,1001.87) .. (-626.15,1000.25)
 .. controls (-627.95,998.63) and (-646.31,984.77) .. (-649.19,981.17)
 .. controls (-652.07,977.57) and (-659.09,970.91) .. (-662.51,970.19)
 .. controls (-665.93,969.47) and (-665.57,972.89) .. (-673.49,970.37)
 .. controls (-681.41,967.85) and (-693.29,954.89) .. (-702.29,949.85)
 .. controls (-711.29,944.81) and (-712.01,940.85) .. (-715.25,934.37)
 .. controls (-718.49,927.89) and (-705.89,915.29) .. (-695.45,900.53)
 .. controls (-685.01,885.77) and (-690.05,871.37) .. (-688.97,864.53)
 .. controls (-687.89,857.69) and (-686.09,834.65) .. (-685.37,821.69)
 .. controls (-684.65,808.73) and (-690.05,810.89) .. (-699.05,810.89)
 .. controls (-708.05,810.89) and (-713.45,810.89) .. (-717.05,809.45)
 .. controls (-720.65,808.01) and (-726.77,791.81) .. (-727.13,789.29)
 .. controls (-727.49,786.77) and (-736.12,769.85) .. (-738.64,763.01)
 .. controls (-741.16,756.17) and (-745.48,758.69) .. (-749.08,759.05)
 .. controls (-752.68,759.41) and (-780.76,762.30) .. (-784.01,762.30)
 .. controls (-787.25,762.30) and (-824.69,767.70) .. (-829.01,767.70)
 .. controls (-833.33,767.70) and (-859.25,764.46) .. (-863.93,763.02)
),
1,((-844.49,693.90)
 .. controls (-841.25,697.14) and (-832.25,706.14) .. (-823.97,702.18)
 .. controls (-815.69,698.22) and (-795.17,700.74) .. (-789.77,702.90)
 .. controls (-784.37,705.06) and (-771.05,712.62) .. (-763.12,708.66)
 .. controls (-755.20,704.70) and (-730.00,702.18) .. (-722.08,701.10)
 .. controls (-714.16,700.02) and (-675.29,708.30) .. (-672.05,717.66)
 .. controls (-668.81,727.02) and (-656.21,752.57) .. (-658.01,757.61)
 .. controls (-659.81,762.65) and (-662.33,782.09) .. (-666.29,787.13)
 .. controls (-670.25,792.17) and (-673.49,794.69) .. (-673.49,794.69)
 .. controls (-673.49,794.69) and (-671.33,798.65) .. (-669.17,803.69)
 .. controls (-667.01,808.73) and (-663.77,826.01) .. (-663.41,830.33)
 .. controls (-663.05,834.65) and (-664.49,846.53) .. (-665.21,848.69)
 .. controls (-665.93,850.85) and (-667.01,852.65) .. (-664.85,859.13)
 .. controls (-662.69,865.61) and (-662.69,879.29) .. (-664.13,882.89)
 .. controls (-665.57,886.49) and (-669.53,904.13) .. (-665.57,913.13)
 .. controls (-661.61,922.13) and (-656.39,928.25) .. (-656.03,932.93)
 .. controls (-655.67,937.61) and (-657.29,941.57) .. (-657.83,944.09)
 .. controls (-658.37,946.61) and (-663.05,948.23) .. (-657.29,952.37)
 .. controls (-651.53,956.51) and (-638.93,963.17) .. (-635.51,963.17)
 .. controls (-632.09,963.17) and (-611.03,970.73) .. (-607.43,973.79)
 .. controls (-603.83,976.85) and (-582.77,989.99) .. (-579.71,990.89)
 .. controls (-576.65,991.78) and (-548.75,1004.56) .. (-539.57,1013.02)
 .. controls (-530.39,1021.48) and (-515.81,1036.06) .. (-512.03,1038.94)
 .. controls (-508.25,1041.82) and (-485.21,1062.88) .. (-481.43,1065.22)
 .. controls (-477.65,1067.56) and (-460.91,1077.10) .. (-455.69,1080.16)
 .. controls (-450.47,1083.22) and (-426.53,1101.94) .. (-424.01,1104.82)
 .. controls (-421.49,1107.70) and (-400.61,1126.41) .. (-392.51,1129.29)
 .. controls (-384.41,1132.17) and (-372.89,1135.41) .. (-367.31,1137.21)
 .. controls (-361.73,1139.01) and (-351.11,1140.45) .. (-348.41,1140.09)
 .. controls (-345.71,1139.73) and (-333.11,1135.23) .. (-328.43,1135.59)
 .. controls (-323.75,1135.95) and (-314.03,1137.75) .. (-312.23,1136.85)
 .. controls (-310.43,1135.95) and (-300.89,1129.65) .. (-297.47,1128.03)
 .. controls (-294.05,1126.41) and (-251.21,1099.22) .. (-245.81,1098.50)
 .. controls (-240.41,1097.78) and (-220.80,1081.40) .. (-216.30,1080.86)
 .. controls (-211.80,1080.32) and (-196.50,1079.42) .. (-188.21,1070.24)
 .. controls (-179.93,1061.06) and (-174.53,1056.20) .. (-171.11,1055.12)
 .. controls (-167.69,1054.04) and (-164.27,1051.52) .. (-161.75,1047.92)
 .. controls (-159.23,1044.32) and (-150.77,1029.92) .. (-150.05,1027.22)
 .. controls (-149.33,1024.52) and (-141.77,997.15) .. (-139.43,993.73)
 .. controls (-137.09,990.31) and (-130.07,986.35) .. (-124.13,986.35)
 .. controls (-118.19,986.35) and (-108.47,976.81) .. (-104.87,972.67)
 .. controls (-101.27,968.53) and (-80.57,950.53) .. (-77.51,946.93)
 .. controls (-74.45,943.33) and (-55.55,932.35) .. (-52.31,930.01)
 .. controls (-49.07,927.67) and (-18.29,907.15) .. (-13.79,906.79)
 .. controls (-9.29,906.43) and (16.45,901.21) .. (21.85,900.31)
 .. controls (27.25,899.41) and (54.25,889.51) .. (58.93,886.99)
 .. controls (63.61,884.47) and (77.47,875.83) .. (79.81,874.75)
 .. controls (82.15,873.67) and (103.21,863.59) .. (107.71,861.79)
 .. controls (112.21,859.99) and (120.67,848.11) .. (124.09,845.23)
 .. controls (127.50,842.35) and (144.60,828.13) .. (150.36,825.97)
 .. controls (156.12,823.81) and (173.76,826.87) .. (178.08,828.49)
 .. controls (182.40,830.11) and (197.52,833.17) .. (203.64,832.81)
 .. controls (209.76,832.45) and (226.86,831.01) .. (231.36,828.85)
 .. controls (235.86,826.69) and (240.90,828.13) .. (245.40,828.13)
 .. controls (249.90,828.13) and (263.40,825.07) .. (267.90,823.27)
 .. controls (272.40,821.47) and (313.80,801.13) .. (316.14,799.51)
 .. controls (318.48,797.89) and (340.07,789.07) .. (344.57,788.35)
 .. controls (349.07,787.63) and (371.75,783.30) .. (377.87,780.42)
 .. controls (383.99,777.54) and (406.14,776.46) .. (411.18,776.10)
 .. controls (416.22,775.74) and (432.60,775.38) .. (437.10,776.28)
 .. controls (441.60,777.18) and (455.82,779.70) .. (460.86,777.90)
 .. controls (465.90,776.10) and (480.48,770.88) .. (483.90,767.46)
 .. controls (487.32,764.04) and (502.80,750.00) .. (505.86,748.20)
 .. controls (508.92,746.40) and (535.92,730.74) .. (539.88,729.30)
 .. controls (543.84,727.86) and (574.08,718.68) .. (582.54,715.98)
 .. controls (591.00,713.28) and (617.46,702.66) .. (623.22,700.14)
 .. controls (628.98,697.62) and (655.98,686.29) .. (659.40,685.75)
 .. controls (662.82,685.21) and (671.46,686.29) .. (674.70,687.01)
 .. controls (677.94,687.73) and (680.64,691.33) .. (684.78,689.89)
 .. controls (688.92,688.45) and (692.52,684.67) .. (695.22,682.15)
 .. controls (697.92,679.63) and (709.98,677.29) .. (713.22,673.33)
 .. controls (716.46,669.37) and (728.34,645.60) .. (730.32,640.92)
 .. controls (732.30,636.24) and (739.14,622.56) .. (740.04,618.42)
 .. controls (740.94,614.28) and (740.94,607.08) .. (742.74,601.14)
 .. controls (744.54,595.20) and (747.96,587.64) .. (746.16,582.24)
 .. controls (744.36,576.84) and (741.66,570.90) .. (738.60,564.42)
 .. controls (735.54,557.94) and (728.34,539.04) .. (728.34,535.44)
 .. controls (728.34,531.84) and (727.44,532.56) .. (731.04,525.19)
 .. controls (734.64,517.81) and (738.60,512.05) .. (740.40,506.83)
 .. controls (742.20,501.61) and (746.88,477.49) .. (746.34,469.75)
 .. controls (745.80,462.01) and (748.68,445.63) .. (749.75,440.41)
 .. controls (750.83,435.19) and (755.69,404.95) .. (756.41,400.45)
 .. controls (757.13,395.95) and (763.43,370.75) .. (765.41,366.43)
 .. controls (767.39,362.11) and (772.07,335.47) .. (770.81,330.07)
 .. controls (769.55,324.67) and (757.13,316.21) .. (751.19,312.61)
 .. controls (745.25,309.01) and (689.27,289.39) .. (684.59,287.59)
 .. controls (679.91,285.79) and (634.37,270.85) .. (625.37,266.35)
 .. controls (616.37,261.85) and (580.01,251.05) .. (577.85,249.43)
 .. controls (575.69,247.81) and (567.41,245.11) .. (561.11,235.03)
 .. controls (554.81,224.95) and (537.53,203.53) .. (535.55,199.93)
 .. controls (533.57,196.33) and (519.71,180.31) .. (516.47,175.99)
 .. controls (513.23,171.67) and (500.99,160.69) .. (498.29,156.55)
 .. controls (495.59,152.41) and (486.77,141.07) .. (488.93,134.41)
 .. controls (491.09,127.75) and (493.07,120.72) .. (493.07,115.86)
 .. controls (493.07,111.01) and (492.16,71.95) .. (492.34,65.11)
 .. controls (492.52,58.27) and (492.16,38.11) .. (492.52,32.17)
 .. controls (492.88,26.23) and (497.74,-1.13) .. (499.54,-6.35)
 .. controls (501.34,-11.57) and (503.50,-21.11) .. (505.48,-26.51)
 .. controls (507.46,-31.91) and (505.48,-41.45) .. (506.74,-44.33)
 .. controls (508.00,-47.21) and (512.50,-54.59) .. (516.46,-57.10)
 .. controls (520.42,-59.62) and (535.72,-78.88) .. (538.06,-84.82)
 .. controls (540.40,-90.76) and (547.60,-103.54) .. (553.18,-103.90)
 .. controls (558.76,-104.26) and (563.08,-106.42) .. (566.68,-114.88)
 .. controls (570.28,-123.34) and (588.99,-154.30) .. (593.31,-158.80)
 .. controls (597.63,-163.30) and (604.83,-174.28) .. (607.35,-176.62)
 .. controls (609.87,-178.96) and (613.47,-176.98) .. (615.63,-184.18)
 .. controls (617.79,-191.38) and (617.79,-199.85) .. (619.59,-203.45)
 .. controls (621.39,-207.05) and (622.11,-211.73) .. (627.87,-213.17)
 .. controls (633.63,-214.61) and (640.29,-224.69) .. (642.45,-229.01)
 .. controls (644.61,-233.33) and (646.23,-249.53) .. (644.61,-259.25)
 .. controls (642.99,-268.97) and (641.19,-285.89) .. (641.91,-288.95)
 .. controls (642.63,-292.01) and (648.75,-309.65) .. (651.81,-317.21)
 .. controls (654.87,-324.77) and (657.57,-341.32) .. (659.01,-349.96)
 .. controls (660.45,-358.60) and (660.99,-385.60) .. (660.81,-389.74)
 .. controls (660.63,-393.88) and (658.28,-413.14) .. (658.28,-417.10)
 .. controls (658.28,-421.06) and (659.18,-431.86) .. (663.50,-438.34)
 .. controls (667.82,-444.82) and (668.00,-450.22) .. (666.02,-457.78)
 .. controls (664.04,-465.34) and (657.20,-478.84) .. (654.32,-485.32)
 .. controls (651.44,-491.80) and (651.08,-492.16) .. (651.98,-496.12)
 .. controls (652.88,-500.08) and (645.32,-516.64) .. (644.42,-518.62)
 .. controls (643.52,-520.60) and (632.54,-542.20) .. (629.66,-547.06)
 .. controls (626.78,-551.92) and (622.82,-568.30) .. (622.46,-572.44)
 .. controls (622.10,-576.58) and (620.48,-589.00) .. (620.12,-591.88)
 .. controls (619.76,-594.76) and (618.50,-599.44) .. (615.62,-601.78)
 .. controls (612.74,-604.12) and (598.34,-605.74) .. (594.20,-606.46)
 .. controls (590.06,-607.17) and (579.08,-613.11) .. (577.64,-619.59)
 .. controls (576.20,-626.07) and (565.04,-653.07) .. (559.64,-657.75)
 .. controls (554.23,-662.43) and (539.11,-675.57) .. (534.61,-680.25)
 .. controls (530.11,-684.93) and (519.13,-691.41) .. (513.91,-695.01)
 .. controls (508.69,-698.61) and (490.15,-712.65) .. (484.39,-714.09)
 .. controls (478.63,-715.53) and (461.89,-721.65) .. (454.15,-725.79)
 .. controls (446.41,-729.93) and (435.97,-736.95) .. (433.09,-740.73)
 .. controls (430.21,-744.51) and (415.27,-756.40) .. (409.87,-757.30)
 .. controls (404.47,-758.20) and (394.75,-756.58) .. (389.53,-755.32)
 .. controls (384.31,-754.06) and (359.29,-751.54) .. (352.09,-750.46)
 .. controls (344.89,-749.38) and (332.11,-747.58) .. (327.79,-748.12)
 .. controls (323.47,-748.66) and (300.43,-739.30) .. (289.09,-739.48)
 .. controls (277.75,-739.66) and (250.21,-736.05) .. (234.19,-741.45)
 .. controls (218.17,-746.85) and (198.37,-751.71) .. (195.67,-756.03)
 .. controls (192.97,-760.35) and (184.33,-772.77) .. (181.99,-776.37)
 .. controls (179.65,-779.97) and (166.69,-793.65) .. (161.29,-793.29)
 .. controls (155.90,-792.93) and (134.84,-794.37) .. (131.06,-795.99)
 .. controls (127.28,-797.61) and (121.88,-802.47) .. (124.04,-810.93)
 .. controls (126.20,-819.39) and (125.48,-828.75) .. (125.84,-834.33)
 .. controls (126.20,-839.91) and (123.50,-876.09) .. (122.42,-882.21)
 .. controls (121.34,-888.33) and (115.76,-915.51) .. (111.80,-921.63)
 .. controls (107.84,-927.75) and (84.44,-967.71) .. (80.30,-973.29)
 .. controls (76.16,-978.87) and (57.26,-1003.89) .. (54.74,-1009.65)
 .. controls (52.22,-1015.41) and (44.84,-1036.10) .. (40.70,-1043.48)
 .. controls (36.56,-1050.86) and (23.06,-1071.92) .. (19.64,-1076.24)
 .. controls (16.22,-1080.56) and (7.04,-1096.58) .. (1.10,-1105.04)
 .. controls (-4.84,-1113.50) and (-15.46,-1128.08) .. (-18.70,-1134.20)
 .. controls (-21.94,-1140.32) and (-29.68,-1145.90) .. (-31.30,-1149.14)
 .. controls (-32.92,-1152.38) and (-35.62,-1156.70) .. (-35.62,-1156.70)
));
draw_downscrap;
endfig;
beginfig(15);
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-844.49,693.90)
 .. controls (-841.25,697.14) and (-832.25,706.14) .. (-823.97,702.18)
 .. controls (-815.69,698.22) and (-795.17,700.74) .. (-789.77,702.90)
 .. controls (-784.37,705.06) and (-771.05,712.62) .. (-763.12,708.66)
 .. controls (-755.20,704.70) and (-730.00,702.18) .. (-722.08,701.10)
 .. controls (-714.16,700.02) and (-675.29,708.30) .. (-672.05,717.66)
 .. controls (-668.81,727.02) and (-656.21,752.57) .. (-658.01,757.61)
 .. controls (-659.81,762.65) and (-662.33,782.09) .. (-666.29,787.13)
 .. controls (-670.25,792.17) and (-673.49,794.69) .. (-673.49,794.69)
 .. controls (-673.49,794.69) and (-671.33,798.65) .. (-669.17,803.69)
 .. controls (-667.01,808.73) and (-663.77,826.01) .. (-663.41,830.33)
 .. controls (-663.05,834.65) and (-664.49,846.53) .. (-665.21,848.69)
 .. controls (-665.93,850.85) and (-667.01,852.65) .. (-664.85,859.13)
 .. controls (-662.69,865.61) and (-662.69,879.29) .. (-664.13,882.89)
 .. controls (-665.57,886.49) and (-669.53,904.13) .. (-665.57,913.13)
 .. controls (-661.61,922.13) and (-656.39,928.25) .. (-656.03,932.93)
 .. controls (-655.67,937.61) and (-657.29,941.57) .. (-657.83,944.09)
 .. controls (-658.37,946.61) and (-663.05,948.23) .. (-657.29,952.37)
 .. controls (-651.53,956.51) and (-638.93,963.17) .. (-635.51,963.17)
 .. controls (-632.09,963.17) and (-611.03,970.73) .. (-607.43,973.79)
 .. controls (-603.83,976.85) and (-582.77,989.99) .. (-579.71,990.89)
 .. controls (-576.65,991.78) and (-548.75,1004.56) .. (-539.57,1013.02)
 .. controls (-530.39,1021.48) and (-515.81,1036.06) .. (-512.03,1038.94)
 .. controls (-508.25,1041.82) and (-485.21,1062.88) .. (-481.43,1065.22)
 .. controls (-477.65,1067.56) and (-460.91,1077.10) .. (-455.69,1080.16)
 .. controls (-450.47,1083.22) and (-426.53,1101.94) .. (-424.01,1104.82)
 .. controls (-421.49,1107.70) and (-400.61,1126.41) .. (-392.51,1129.29)
 .. controls (-384.41,1132.17) and (-372.89,1135.41) .. (-367.31,1137.21)
 .. controls (-361.73,1139.01) and (-351.11,1140.45) .. (-348.41,1140.09)
 .. controls (-345.71,1139.73) and (-333.11,1135.23) .. (-328.43,1135.59)
 .. controls (-323.75,1135.95) and (-314.03,1137.75) .. (-312.23,1136.85)
 .. controls (-310.43,1135.95) and (-300.89,1129.65) .. (-297.47,1128.03)
 .. controls (-294.05,1126.41) and (-251.21,1099.22) .. (-245.81,1098.50)
 .. controls (-240.41,1097.78) and (-220.80,1081.40) .. (-216.30,1080.86)
 .. controls (-211.80,1080.32) and (-196.50,1079.42) .. (-188.21,1070.24)
 .. controls (-179.93,1061.06) and (-174.53,1056.20) .. (-171.11,1055.12)
 .. controls (-167.69,1054.04) and (-164.27,1051.52) .. (-161.75,1047.92)
 .. controls (-159.23,1044.32) and (-150.77,1029.92) .. (-150.05,1027.22)
 .. controls (-149.33,1024.52) and (-141.77,997.15) .. (-139.43,993.73)
 .. controls (-137.09,990.31) and (-130.07,986.35) .. (-124.13,986.35)
 .. controls (-118.19,986.35) and (-108.47,976.81) .. (-104.87,972.67)
 .. controls (-101.27,968.53) and (-80.57,950.53) .. (-77.51,946.93)
 .. controls (-74.45,943.33) and (-55.55,932.35) .. (-52.31,930.01)
 .. controls (-49.07,927.67) and (-18.29,907.15) .. (-13.79,906.79)
 .. controls (-9.29,906.43) and (16.45,901.21) .. (21.85,900.31)
 .. controls (27.25,899.41) and (54.25,889.51) .. (58.93,886.99)
 .. controls (63.61,884.47) and (77.47,875.83) .. (79.81,874.75)
 .. controls (82.15,873.67) and (103.21,863.59) .. (107.71,861.79)
 .. controls (112.21,859.99) and (120.67,848.11) .. (124.09,845.23)
 .. controls (127.50,842.35) and (144.60,828.13) .. (150.36,825.97)
 .. controls (156.12,823.81) and (173.76,826.87) .. (178.08,828.49)
 .. controls (182.40,830.11) and (197.52,833.17) .. (203.64,832.81)
 .. controls (209.76,832.45) and (226.86,831.01) .. (231.36,828.85)
 .. controls (235.86,826.69) and (240.90,828.13) .. (245.40,828.13)
 .. controls (249.90,828.13) and (263.40,825.07) .. (267.90,823.27)
 .. controls (272.40,821.47) and (313.80,801.13) .. (316.14,799.51)
 .. controls (318.48,797.89) and (340.07,789.07) .. (344.57,788.35)
 .. controls (349.07,787.63) and (371.75,783.30) .. (377.87,780.42)
 .. controls (383.99,777.54) and (406.14,776.46) .. (411.18,776.10)
 .. controls (416.22,775.74) and (432.60,775.38) .. (437.10,776.28)
 .. controls (441.60,777.18) and (455.82,779.70) .. (460.86,777.90)
 .. controls (465.90,776.10) and (480.48,770.88) .. (483.90,767.46)
 .. controls (487.32,764.04) and (502.80,750.00) .. (505.86,748.20)
 .. controls (508.92,746.40) and (535.92,730.74) .. (539.88,729.30)
 .. controls (543.84,727.86) and (574.08,718.68) .. (582.54,715.98)
 .. controls (591.00,713.28) and (617.46,702.66) .. (623.22,700.14)
 .. controls (628.98,697.62) and (655.98,686.29) .. (659.40,685.75)
 .. controls (662.82,685.21) and (671.46,686.29) .. (674.70,687.01)
 .. controls (677.94,687.73) and (680.64,691.33) .. (684.78,689.89)
 .. controls (688.92,688.45) and (692.52,684.67) .. (695.22,682.15)
 .. controls (697.92,679.63) and (709.98,677.29) .. (713.22,673.33)
 .. controls (716.46,669.37) and (728.34,645.60) .. (730.32,640.92)
 .. controls (732.30,636.24) and (739.14,622.56) .. (740.04,618.42)
 .. controls (740.94,614.28) and (740.94,607.08) .. (742.74,601.14)
 .. controls (744.54,595.20) and (747.96,587.64) .. (746.16,582.24)
 .. controls (744.36,576.84) and (741.66,570.90) .. (738.60,564.42)
 .. controls (735.54,557.94) and (728.34,539.04) .. (728.34,535.44)
 .. controls (728.34,531.84) and (727.44,532.56) .. (731.04,525.19)
 .. controls (734.64,517.81) and (738.60,512.05) .. (740.40,506.83)
 .. controls (742.20,501.61) and (746.88,477.49) .. (746.34,469.75)
 .. controls (745.80,462.01) and (748.68,445.63) .. (749.75,440.41)
 .. controls (750.83,435.19) and (755.69,404.95) .. (756.41,400.45)
 .. controls (757.13,395.95) and (763.43,370.75) .. (765.41,366.43)
 .. controls (767.39,362.11) and (772.07,335.47) .. (770.81,330.07)
 .. controls (769.55,324.67) and (757.13,316.21) .. (751.19,312.61)
 .. controls (745.25,309.01) and (689.27,289.39) .. (684.59,287.59)
 .. controls (679.91,285.79) and (634.37,270.85) .. (625.37,266.35)
 .. controls (616.37,261.85) and (580.01,251.05) .. (577.85,249.43)
 .. controls (575.69,247.81) and (567.41,245.11) .. (561.11,235.03)
 .. controls (554.81,224.95) and (537.53,203.53) .. (535.55,199.93)
 .. controls (533.57,196.33) and (519.71,180.31) .. (516.47,175.99)
 .. controls (513.23,171.67) and (500.99,160.69) .. (498.29,156.55)
 .. controls (495.59,152.41) and (486.77,141.07) .. (488.93,134.41)
 .. controls (491.09,127.75) and (493.07,120.72) .. (493.07,115.86)
 .. controls (493.07,111.01) and (492.16,71.95) .. (492.34,65.11)
 .. controls (492.52,58.27) and (492.16,38.11) .. (492.52,32.17)
 .. controls (492.88,26.23) and (497.74,-1.13) .. (499.54,-6.35)
 .. controls (501.34,-11.57) and (503.50,-21.11) .. (505.48,-26.51)
 .. controls (507.46,-31.91) and (505.48,-41.45) .. (506.74,-44.33)
 .. controls (508.00,-47.21) and (512.50,-54.59) .. (516.46,-57.10)
 .. controls (520.42,-59.62) and (535.72,-78.88) .. (538.06,-84.82)
 .. controls (540.40,-90.76) and (547.60,-103.54) .. (553.18,-103.90)
 .. controls (558.76,-104.26) and (563.08,-106.42) .. (566.68,-114.88)
 .. controls (570.28,-123.34) and (588.99,-154.30) .. (593.31,-158.80)
 .. controls (597.63,-163.30) and (604.83,-174.28) .. (607.35,-176.62)
 .. controls (609.87,-178.96) and (613.47,-176.98) .. (615.63,-184.18)
 .. controls (617.79,-191.38) and (617.79,-199.85) .. (619.59,-203.45)
 .. controls (621.39,-207.05) and (622.11,-211.73) .. (627.87,-213.17)
 .. controls (633.63,-214.61) and (640.29,-224.69) .. (642.45,-229.01)
 .. controls (644.61,-233.33) and (646.23,-249.53) .. (644.61,-259.25)
 .. controls (642.99,-268.97) and (641.19,-285.89) .. (641.91,-288.95)
 .. controls (642.63,-292.01) and (648.75,-309.65) .. (651.81,-317.21)
 .. controls (654.87,-324.77) and (657.57,-341.32) .. (659.01,-349.96)
 .. controls (660.45,-358.60) and (660.99,-385.60) .. (660.81,-389.74)
 .. controls (660.63,-393.88) and (658.28,-413.14) .. (658.28,-417.10)
 .. controls (658.28,-421.06) and (659.18,-431.86) .. (663.50,-438.34)
 .. controls (667.82,-444.82) and (668.00,-450.22) .. (666.02,-457.78)
 .. controls (664.04,-465.34) and (657.20,-478.84) .. (654.32,-485.32)
 .. controls (651.44,-491.80) and (651.08,-492.16) .. (651.98,-496.12)
 .. controls (652.88,-500.08) and (645.32,-516.64) .. (644.42,-518.62)
 .. controls (643.52,-520.60) and (632.54,-542.20) .. (629.66,-547.06)
 .. controls (626.78,-551.92) and (622.82,-568.30) .. (622.46,-572.44)
 .. controls (622.10,-576.58) and (620.48,-589.00) .. (620.12,-591.88)
 .. controls (619.76,-594.76) and (618.50,-599.44) .. (615.62,-601.78)
 .. controls (612.74,-604.12) and (598.34,-605.74) .. (594.20,-606.46)
 .. controls (590.06,-607.17) and (579.08,-613.11) .. (577.64,-619.59)
 .. controls (576.20,-626.07) and (565.04,-653.07) .. (559.64,-657.75)
 .. controls (554.23,-662.43) and (539.11,-675.57) .. (534.61,-680.25)
 .. controls (530.11,-684.93) and (519.13,-691.41) .. (513.91,-695.01)
 .. controls (508.69,-698.61) and (490.15,-712.65) .. (484.39,-714.09)
 .. controls (478.63,-715.53) and (461.89,-721.65) .. (454.15,-725.79)
 .. controls (446.41,-729.93) and (435.97,-736.95) .. (433.09,-740.73)
 .. controls (430.21,-744.51) and (415.27,-756.40) .. (409.87,-757.30)
 .. controls (404.47,-758.20) and (394.75,-756.58) .. (389.53,-755.32)
 .. controls (384.31,-754.06) and (359.29,-751.54) .. (352.09,-750.46)
 .. controls (344.89,-749.38) and (332.11,-747.58) .. (327.79,-748.12)
 .. controls (323.47,-748.66) and (300.43,-739.30) .. (289.09,-739.48)
 .. controls (277.75,-739.66) and (250.21,-736.05) .. (234.19,-741.45)
 .. controls (218.17,-746.85) and (198.37,-751.71) .. (195.67,-756.03)
 .. controls (192.97,-760.35) and (184.33,-772.77) .. (181.99,-776.37)
 .. controls (179.65,-779.97) and (166.69,-793.65) .. (161.29,-793.29)
 .. controls (155.90,-792.93) and (134.84,-794.37) .. (131.06,-795.99)
 .. controls (127.28,-797.61) and (121.88,-802.47) .. (124.04,-810.93)
 .. controls (126.20,-819.39) and (125.48,-828.75) .. (125.84,-834.33)
 .. controls (126.20,-839.91) and (123.50,-876.09) .. (122.42,-882.21)
 .. controls (121.34,-888.33) and (115.76,-915.51) .. (111.80,-921.63)
 .. controls (107.84,-927.75) and (84.44,-967.71) .. (80.30,-973.29)
 .. controls (76.16,-978.87) and (57.26,-1003.89) .. (54.74,-1009.65)
 .. controls (52.22,-1015.41) and (44.84,-1036.10) .. (40.70,-1043.48)
 .. controls (36.56,-1050.86) and (23.06,-1071.92) .. (19.64,-1076.24)
 .. controls (16.22,-1080.56) and (7.04,-1096.58) .. (1.10,-1105.04)
 .. controls (-4.84,-1113.50) and (-15.46,-1128.08) .. (-18.70,-1134.20)
 .. controls (-21.94,-1140.32) and (-29.68,-1145.90) .. (-31.30,-1149.14)
 .. controls (-32.92,-1152.38) and (-35.62,-1156.70) .. (-35.62,-1156.70)
));
drawoptions();
p_rimstonepool((-44.21,965.65),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-52.13,954.13),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-64.37,948.73),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-81.65,961.33),22.1,1.00,(0,0));
drawoptions();
p_rimstonepool((-69.77,963.85),38.0,1.00,(0,0));
drawoptions();
p_rimstonepool((-58.61,977.89),65.2,1.00,(0,0));
drawoptions();
p_rimstonepool((-97.13,977.89),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-87.77,980.05),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-78.41,985.81),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-116.21,990.13),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-103.97,994.45),45.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-94.97,999.13),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-133.49,1002.73),25.2,1.00,(0,0));
drawoptions();
p_rimstonepool((-120.17,1005.25),34.7,1.00,(0,0));
drawoptions();
p_rimstonepool((-107.57,1008.49),46.5,1.00,(0,0));
drawoptions();
p_rimstonepool((-142.49,1016.78),17.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-133.49,1019.30),33.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-124.49,1022.90),39.5,1.00,(0,0));
drawoptions();
p_rimstonepool((-143.21,1031.54),35.1,1.00,(0,0));
drawoptions();
p_rimstonepool((-132.05,1035.50),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-168.05,1071.14),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-175.97,1067.18),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-187.85,1080.50),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-209.46,1086.62),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-198.66,1090.94),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-225.65,1099.58),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-209.45,1102.82),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-246.17,1107.14),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-236.45,1110.74),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-226.37,1113.62),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-270.29,1122.26),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-254.81,1125.86),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-289.73,1132.35),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-273.17,1133.42),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-300.89,1138.83),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-294.77,1143.87),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-313.49,1148.55),47.6,1.00,(0,0));
drawoptions();
p_stalactite((-285.41,1160.78),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-246.17,1142.06),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-151.49,1080.50),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-136.73,1062.50),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-112.25,1039.81),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((107.71,943.69),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-282.53,1102.11),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-237.54,1081.22),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-184.61,1051.34),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((-165.53,1031.90),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((-153.65,999.85),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-21.17,996.97),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((29.95,877.45),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((62.71,865.57),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((92.23,850.81),0.0,1.00,(0,0));
drawoptions();
p_pillar((71.71,963.13),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((43.63,925.33),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((75.31,909.85),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((104.11,895.81),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((-6.05,933.97),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-490.61,1100.32),0.0,1.00,(0,0));
drawoptions();
p_crystal((-442.37,1078.72),0.0,1.00,(0,0));
drawoptions();
p_crystal((-474.41,1126.96),0.0,1.00,(0,0));
drawoptions();
p_crystal((-453.88,1151.08),0.0,1.00,(0,0));
drawoptions();
p_gradient((-55.37,941.89),31.9,1.00,(0,0));
drawoptions();
p_gradient((-42.05,957.73),48.3,1.00,(0,0));
drawoptions();
p_gradient((-75.89,957.37),8.1,1.00,(0,0));
drawoptions();
p_gradient((-92.81,977.17),346.7,1.00,(0,0));
drawoptions();
p_gradient((-89.21,999.49),57.4,1.00,(0,0));
drawoptions();
p_rimstonepool((-696.17,800.09),300.7,1.00,(0,0));
drawoptions();
p_rimstonepool((-685.73,792.53),300.7,1.00,(0,0));
drawoptions();
p_rimstonepool((-684.65,803.33),300.7,1.00,(0,0));
drawoptions();
p_rimstonepool((-694.01,784.61),300.7,1.00,(0,0));
drawoptions();
p_rimstonepool((-685.37,769.49),300.7,1.00,(0,0));
drawoptions();
p_gradient((-673.49,775.61),360.0,1.00,(0,0));
drawoptions();
p_gradient((-690.41,777.77),321.9,1.00,(0,0));
drawoptions();
p_gradient((-677.09,757.61),351.8,1.00,(0,0));
drawoptions();
p_gradient((-794.81,741.78),264.5,1.00,(0,0));
drawoptions();
p_gradient((-799.49,720.18),297.8,1.00,(0,0));
drawoptions();
p_rimstonepool((-670.25,764.81),351.4,1.00,(0,0));
drawoptions();
p_rimstonepool((-685.37,769.49),351.4,1.00,(0,0));
drawoptions();
p_rimstonepool((-677.45,783.89),351.4,1.00,(0,0));
drawoptions();
p_rimstonepool((-685.73,792.53),321.1,1.00,(0,0));
drawoptions();
p_rimstonepool((-684.65,803.33),321.1,1.00,(0,0));
drawoptions();
p_rimstonepool((-696.17,800.09),311.9,1.00,(0,0));
drawoptions();
p_rimstonepool((-694.01,784.61),332.6,1.00,(0,0));
drawoptions();
p_gradient((-64.01,981.13),40.1,1.00,(0,0));
drawoptions();
p_crystal((-443.44,1159.00),0.0,1.00,(0,0));
drawoptions();
p_crystal((-464.68,1138.48),0.0,1.00,(0,0));
drawoptions();
p_crystal((-430.84,1168.35),0.0,1.00,(0,0));
drawoptions();
p_crystal((-417.16,1176.99),0.0,1.00,(0,0));
drawoptions();
p_crystal((-404.20,1183.83),0.0,1.00,(0,0));
drawoptions();
p_crystal((-393.40,1191.75),0.0,1.00,(0,0));
drawoptions();
p_crystal((-430.13,1087.72),0.0,1.00,(0,0));
drawoptions();
p_crystal((-417.17,1097.80),0.0,1.00,(0,0));
drawoptions();
p_crystal((-406.37,1108.23),0.0,1.00,(0,0));
drawoptions();
p_crystal((-393.05,1118.31),0.0,1.00,(0,0));
drawoptions();
p_crystal((-381.17,1125.15),0.0,1.00,(0,0));
drawoptions();
p_crystal((-367.13,1130.19),0.0,1.00,(0,0));
drawoptions();
p_rimstonepool((-306.29,1154.67),47.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-153.29,1043.42),26.3,1.00,(0,0));
drawoptions();
p_rimstonepool((-142.13,1046.30),47.6,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((1.69,996.43)
 .. controls (-0.11,994.81) and (-11.09,986.89) .. (-13.61,985.45)
 .. controls (-16.13,984.01) and (-29.81,978.43) .. (-35.57,978.07)
 .. controls (-41.33,977.71) and (-53.39,983.11) .. (-54.83,984.91)
 .. controls (-56.27,986.71) and (-72.83,995.17) .. (-75.35,996.79)
 .. controls (-77.87,998.41) and (-93.35,1008.31) .. (-96.23,1010.11)
 .. controls (-99.11,1011.91) and (-100.37,1015.15) .. (-102.53,1017.49)
 .. controls (-104.69,1019.83) and (-114.41,1027.03) .. (-115.85,1028.65)
 .. controls (-117.29,1030.27) and (-125.21,1039.64) .. (-127.37,1044.14)
 .. controls (-129.53,1048.64) and (-144.65,1054.40) .. (-152.21,1065.20)
 .. controls (-159.77,1076.00) and (-170.75,1082.30) .. (-173.27,1084.10)
 .. controls (-175.79,1085.90) and (-188.21,1093.82) .. (-190.73,1096.70)
 .. controls (-193.26,1099.58) and (-201.36,1106.24) .. (-204.95,1109.66)
 .. controls (-208.55,1113.08) and (-217.19,1117.04) .. (-222.59,1119.74)
 .. controls (-227.99,1122.44) and (-239.51,1127.66) .. (-243.29,1129.64)
 .. controls (-247.07,1131.62) and (-254.99,1136.12) .. (-260.03,1136.84)
 .. controls (-265.07,1137.56) and (-272.27,1140.44) .. (-276.77,1143.14)
 .. controls (-281.27,1145.84) and (-295.85,1152.51) .. (-297.11,1155.39)
 .. controls (-298.37,1158.27) and (-306.83,1167.99) .. (-309.71,1172.85)
 .. controls (-312.59,1177.71) and (-326.98,1183.65) .. (-329.14,1185.63)
 .. controls (-331.30,1187.61) and (-357.04,1196.61) .. (-360.46,1198.05)
 .. controls (-363.88,1199.49) and (-372.34,1196.25) .. (-374.86,1196.25)
 .. controls (-377.38,1196.25) and (-407.44,1175.55) .. (-409.60,1173.93)
 .. controls (-411.76,1172.31) and (-446.87,1143.16) .. (-450.29,1140.28)
 .. controls (-453.71,1137.40) and (-475.13,1105.36) .. (-477.65,1102.48)
 .. controls (-480.17,1099.60) and (-488.63,1085.92) .. (-490.43,1084.12)
 .. controls (-492.23,1082.32) and (-503.21,1075.66) .. (-509.69,1072.96)
 .. controls (-516.17,1070.26) and (-536.51,1059.28) .. (-539.93,1056.94)
 .. controls (-543.35,1054.60) and (-557.93,1047.58) .. (-561.53,1045.96)
 .. controls (-565.13,1044.34) and (-577.01,1037.86) .. (-578.99,1035.52)
 .. controls (-580.97,1033.18) and (-590.15,1024.72) .. (-594.11,1023.65)
 .. controls (-598.07,1022.57) and (-609.23,1016.99) .. (-611.39,1013.03)
 .. controls (-613.55,1009.07) and (-624.35,1001.87) .. (-626.15,1000.25)
 .. controls (-627.95,998.63) and (-646.31,984.77) .. (-649.19,981.17)
 .. controls (-652.07,977.57) and (-659.09,970.91) .. (-662.51,970.19)
 .. controls (-665.93,969.47) and (-665.57,972.89) .. (-673.49,970.37)
 .. controls (-681.41,967.85) and (-693.29,954.89) .. (-702.29,949.85)
 .. controls (-711.29,944.81) and (-712.01,940.85) .. (-715.25,934.37)
 .. controls (-718.49,927.89) and (-705.89,915.29) .. (-695.45,900.53)
 .. controls (-685.01,885.77) and (-690.05,871.37) .. (-688.97,864.53)
 .. controls (-687.89,857.69) and (-686.09,834.65) .. (-685.37,821.69)
 .. controls (-684.65,808.73) and (-690.05,810.89) .. (-699.05,810.89)
 .. controls (-708.05,810.89) and (-713.45,810.89) .. (-717.05,809.45)
 .. controls (-720.65,808.01) and (-726.77,791.81) .. (-727.13,789.29)
 .. controls (-727.49,786.77) and (-736.12,769.85) .. (-738.64,763.01)
 .. controls (-741.16,756.17) and (-745.48,758.69) .. (-749.08,759.05)
 .. controls (-752.68,759.41) and (-780.76,762.30) .. (-784.01,762.30)
 .. controls (-787.25,762.30) and (-824.69,767.70) .. (-829.01,767.70)
 .. controls (-833.33,767.70) and (-859.25,764.46) .. (-863.93,763.02)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((43.94,-1178.48)
 .. controls (43.94,-1178.48) and (59.78,-1145.54) .. (62.12,-1139.24)
 .. controls (64.46,-1132.94) and (79.04,-1094.78) .. (79.94,-1091.54)
 .. controls (80.84,-1088.30) and (88.40,-1064.90) .. (89.84,-1061.66)
 .. controls (91.28,-1058.42) and (94.16,-1059.32) .. (97.22,-1053.74)
 .. controls (100.28,-1048.16) and (107.84,-1018.46) .. (108.92,-1016.30)
 .. controls (110.00,-1014.15) and (119.36,-983.73) .. (119.54,-979.41)
 .. controls (119.72,-975.09) and (131.24,-949.89) .. (132.14,-945.75)
 .. controls (133.04,-941.61) and (132.86,-930.81) .. (132.50,-928.83)
 .. controls (132.14,-926.85) and (130.88,-917.85) .. (136.64,-912.63)
 .. controls (142.40,-907.41) and (154.46,-892.83) .. (156.44,-890.49)
 .. controls (158.42,-888.15) and (175.16,-872.67) .. (177.32,-871.05)
 .. controls (179.48,-869.43) and (197.84,-849.81) .. (198.56,-848.01)
 .. controls (199.28,-846.21) and (203.78,-842.07) .. (198.92,-832.71)
 .. controls (194.06,-823.35) and (191.36,-818.31) .. (191.36,-816.87)
 .. controls (191.35,-815.43) and (189.01,-811.29) .. (194.41,-810.57)
 .. controls (199.81,-809.85) and (215.29,-810.03) .. (218.53,-812.73)
 .. controls (221.77,-815.43) and (239.05,-830.55) .. (240.49,-832.35)
 .. controls (241.93,-834.15) and (258.85,-843.51) .. (264.43,-841.89)
 .. controls (270.01,-840.27) and (282.79,-842.79) .. (291.97,-828.39)
 .. controls (301.15,-814.00) and (308.89,-811.12) .. (311.77,-805.36)
 .. controls (314.65,-799.60) and (321.85,-787.72) .. (326.89,-787.36)
 .. controls (331.93,-787.00) and (340.75,-784.30) .. (350.11,-787.54)
 .. controls (359.47,-790.78) and (377.29,-787.72) .. (385.93,-796.00)
 .. controls (394.57,-804.28) and (409.69,-813.64) .. (413.65,-814.18)
 .. controls (417.61,-814.72) and (435.26,-815.98) .. (439.76,-813.28)
 .. controls (444.26,-810.58) and (479.90,-785.37) .. (484.40,-780.69)
 .. controls (488.90,-776.01) and (507.79,-760.35) .. (510.31,-757.65)
 .. controls (512.83,-754.95) and (534.25,-739.29) .. (539.29,-736.05)
 .. controls (544.33,-732.81) and (580.87,-711.57) .. (586.27,-705.99)
 .. controls (591.67,-700.41) and (627.32,-675.75) .. (632.54,-672.51)
 .. controls (637.76,-669.27) and (652.70,-656.31) .. (654.68,-646.77)
 .. controls (656.66,-637.23) and (655.58,-630.39) .. (654.32,-628.05)
 .. controls (653.06,-625.71) and (650.72,-617.07) .. (653.96,-611.68)
 .. controls (657.20,-606.28) and (663.32,-599.26) .. (665.66,-596.20)
 .. controls (668.00,-593.14) and (673.94,-581.44) .. (674.84,-578.92)
 .. controls (675.74,-576.40) and (684.38,-551.20) .. (686.00,-545.44)
 .. controls (687.62,-539.68) and (686.90,-531.04) .. (686.72,-527.26)
 .. controls (686.54,-523.48) and (687.98,-517.54) .. (689.78,-513.76)
 .. controls (691.58,-509.98) and (698.24,-495.04) .. (699.68,-491.80)
 .. controls (701.12,-488.56) and (702.74,-477.04) .. (702.74,-473.98)
 .. controls (702.74,-470.92) and (705.98,-448.24) .. (705.80,-441.76)
 .. controls (705.62,-435.28) and (709.40,-418.00) .. (709.76,-412.06)
 .. controls (710.12,-406.12) and (715.70,-381.10) .. (716.96,-377.15)
 .. controls (718.23,-373.19) and (718.41,-361.49) .. (717.51,-356.81)
 .. controls (716.61,-352.13) and (714.45,-326.57) .. (712.83,-322.25)
 .. controls (711.21,-317.93) and (711.03,-305.87) .. (712.11,-299.39)
 .. controls (713.19,-292.91) and (712.29,-281.03) .. (710.85,-276.35)
 .. controls (709.41,-271.67) and (706.89,-256.01) .. (705.09,-252.23)
 .. controls (703.29,-248.45) and (699.51,-241.79) .. (695.91,-235.49)
 .. controls (692.31,-229.19) and (684.03,-216.77) .. (681.15,-214.43)
 .. controls (678.27,-212.09) and (677.01,-214.25) .. (672.51,-211.55)
 .. controls (668.01,-208.85) and (664.59,-210.29) .. (661.17,-201.11)
 .. controls (657.75,-191.93) and (655.77,-183.83) .. (653.61,-179.69)
 .. controls (651.45,-175.55) and (649.11,-168.89) .. (647.85,-166.73)
 .. controls (646.59,-164.57) and (634.89,-144.77) .. (633.45,-142.97)
 .. controls (632.01,-141.16) and (614.92,-128.02) .. (611.32,-125.32)
 .. controls (607.72,-122.62) and (599.44,-117.94) .. (593.86,-111.82)
 .. controls (588.28,-105.70) and (582.52,-100.84) .. (582.52,-95.44)
 .. controls (582.52,-90.04) and (579.82,-81.04) .. (578.92,-77.44)
 .. controls (578.02,-73.84) and (568.48,-57.82) .. (565.96,-52.60)
 .. controls (563.44,-47.38) and (562.90,-41.62) .. (560.02,-37.49)
 .. controls (557.14,-33.35) and (554.08,-29.75) .. (553.54,-29.21)
 .. controls (553.00,-28.67) and (547.06,-27.59) .. (547.42,-20.93)
 .. controls (547.78,-14.27) and (551.38,-11.57) .. (551.92,-10.13)
 .. controls (552.46,-8.69) and (558.94,10.03) .. (557.32,20.83)
 .. controls (555.70,31.63) and (553.00,48.37) .. (552.10,52.51)
 .. controls (551.20,56.65) and (546.70,77.34) .. (545.99,85.98)
 .. controls (545.27,94.62) and (546.17,109.21) .. (550.13,113.17)
 .. controls (554.09,117.13) and (570.83,130.45) .. (578.93,134.05)
 .. controls (587.03,137.65) and (611.33,148.27) .. (614.03,150.25)
 .. controls (616.73,152.23) and (675.23,178.87) .. (681.53,182.65)
 .. controls (687.83,186.43) and (720.23,208.39) .. (723.47,211.09)
 .. controls (726.71,213.79) and (746.15,227.65) .. (749.21,229.09)
 .. controls (752.27,230.53) and (769.01,239.35) .. (772.07,241.87)
 .. controls (775.13,244.39) and (798.17,262.39) .. (803.38,267.07)
 .. controls (808.60,271.75) and (820.84,285.43) .. (823.00,290.29)
 .. controls (825.16,295.15) and (827.33,318.19) .. (826.61,321.07)
 .. controls (825.89,323.95) and (822.83,358.33) .. (819.77,366.97)
 .. controls (816.71,375.61) and (808.61,401.17) .. (806.99,407.83)
 .. controls (805.37,414.49) and (798.53,430.87) .. (797.99,437.53)
 .. controls (797.45,444.19) and (793.50,476.59) .. (791.34,481.81)
 .. controls (789.18,487.03) and (787.38,505.39) .. (785.58,510.61)
 .. controls (783.78,515.83) and (780.54,531.67) .. (781.80,536.17)
 .. controls (783.06,540.67) and (786.12,550.57) .. (787.92,553.63)
 .. controls (789.72,556.69) and (809.34,580.98) .. (813.12,585.84)
 .. controls (816.90,590.70) and (831.12,606.54) .. (833.46,611.04)
 .. controls (835.80,615.54) and (841.74,617.70) .. (841.20,620.22)
 .. controls (840.66,622.74) and (842.82,622.92) .. (837.06,627.96)
 .. controls (831.30,633.00) and (810.42,662.16) .. (806.64,665.40)
 .. controls (802.86,668.64) and (790.08,680.70) .. (782.16,684.48)
 .. controls (774.24,688.26) and (746.52,704.46) .. (744.36,704.82)
 .. controls (742.20,705.18) and (739.86,707.16) .. (731.58,710.22)
 .. controls (723.30,713.28) and (711.78,714.91) .. (705.48,716.53)
 .. controls (699.18,718.15) and (691.44,718.51) .. (687.84,721.39)
 .. controls (684.24,724.27) and (678.48,722.83) .. (678.66,736.15)
 .. controls (678.84,749.47) and (678.84,759.55) .. (683.16,765.31)
 .. controls (687.48,771.07) and (690.72,784.03) .. (690.54,789.79)
 .. controls (690.36,795.55) and (698.28,804.01) .. (695.58,806.17)
 .. controls (692.88,808.33) and (690.90,809.05) .. (682.44,811.03)
 .. controls (673.98,813.01) and (658.14,815.71) .. (653.46,817.15)
 .. controls (648.78,818.59) and (620.70,821.47) .. (608.82,820.38)
 .. controls (596.94,819.30) and (586.68,820.56) .. (583.98,822.00)
 .. controls (581.28,823.44) and (571.20,824.70) .. (564.36,817.86)
 .. controls (557.52,811.02) and (548.70,806.52) .. (542.22,809.04)
 .. controls (535.74,811.56) and (529.62,812.82) .. (525.66,816.24)
 .. controls (521.70,819.66) and (520.80,821.46) .. (513.60,815.88)
 .. controls (506.40,810.30) and (501.90,806.88) .. (498.12,805.08)
 .. controls (494.34,803.28) and (490.20,799.50) .. (485.88,800.40)
 .. controls (481.56,801.30) and (476.70,801.48) .. (475.62,802.92)
 .. controls (474.54,804.36) and (476.88,807.42) .. (471.48,809.40)
 .. controls (466.08,811.38) and (462.12,811.02) .. (458.70,809.04)
 .. controls (455.28,807.06) and (450.96,806.88) .. (441.60,807.60)
 .. controls (432.24,808.32) and (430.62,809.04) .. (421.80,810.30)
 .. controls (412.98,811.56) and (414.42,814.44) .. (407.40,814.80)
 .. controls (400.38,815.16) and (388.32,813.54) .. (383.28,812.64)
 .. controls (378.24,811.74) and (367.79,814.63) .. (362.57,817.33)
 .. controls (357.35,820.03) and (345.84,823.08) .. (341.34,824.70)
 .. controls (336.84,826.32) and (321.18,829.57) .. (316.86,830.83)
 .. controls (312.54,832.09) and (304.08,835.69) .. (292.92,838.03)
 .. controls (281.76,840.37) and (269.88,839.29) .. (262.32,842.71)
 .. controls (254.76,846.13) and (246.66,850.45) .. (242.52,853.15)
 .. controls (238.38,855.85) and (237.12,857.47) .. (231.36,859.27)
 .. controls (225.60,861.07) and (220.20,863.23) .. (213.18,863.95)
 .. controls (206.16,864.67) and (196.98,865.93) .. (194.10,868.45)
 .. controls (191.22,870.97) and (190.86,876.37) .. (191.04,877.99)
 .. controls (191.22,879.61) and (192.30,882.85) .. (192.30,882.85)
));
drawoptions();
p_stalactite((292.38,849.72),0.0,1.00,(0,0));
drawoptions();
p_stalactite((319.38,841.80),0.0,1.00,(0,0));
drawoptions();
p_stalactite((342.42,836.40),0.0,1.00,(0,0));
drawoptions();
p_stalactite((387.78,825.60),0.0,1.00,(0,0));
drawoptions();
p_stalactite((426.30,820.92),0.0,1.00,(0,0));
drawoptions();
p_stalactite((549.06,792.84),0.0,1.00,(0,0));
drawoptions();
p_stalactite((586.86,800.40),0.0,1.00,(0,0));
drawoptions();
p_stalactite((606.66,781.69),0.0,1.00,(0,0));
drawoptions();
p_stalactite((629.34,804.73),0.0,1.00,(0,0));
drawoptions();
p_stalactite((646.98,783.13),0.0,1.00,(0,0));
drawoptions();
p_stalactites((661.74,759.73),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((269.70,804.01),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((303.90,786.37),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((354.65,768.01),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((393.17,760.08),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((420.90,757.20),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((532.14,750.00),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((553.74,741.36),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((591.18,726.24),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((654.90,702.49),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((740.94,544.80),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((749.94,569.28),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((799.98,594.12),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((772.98,620.04),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((721.50,679.09),0.0,1.00,(0,0));
drawoptions();
p_stalactite((814.74,622.20),0.0,1.00,(0,0));
drawoptions();
p_stalactite((692.70,706.45),0.0,1.00,(0,0));
drawoptions();
p_stalactite((715.38,701.77),0.0,1.00,(0,0));
drawoptions();
p_stalactite((572.82,753.60),0.0,1.00,(0,0));
drawoptions();
p_stalactite((790.62,654.24),0.0,1.00,(0,0));
drawoptions();
p_stalactites((640.50,738.85),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((178.44,887.17)
 .. controls (177.72,885.37) and (178.08,878.89) .. (173.04,876.73)
 .. controls (168.00,874.57) and (168.54,874.57) .. (161.88,877.45)
 .. controls (155.22,880.33) and (151.98,882.67) .. (148.38,886.63)
 .. controls (144.78,890.59) and (140.65,895.81) .. (138.31,898.87)
 .. controls (135.97,901.93) and (132.19,907.15) .. (128.77,909.67)
 .. controls (125.35,912.19) and (120.13,914.17) .. (116.89,916.87)
 .. controls (113.65,919.57) and (108.79,923.71) .. (105.91,925.51)
 .. controls (103.03,927.31) and (95.29,930.37) .. (93.85,930.91)
 .. controls (92.41,931.45) and (81.97,935.23) .. (80.17,936.49)
 .. controls (78.37,937.75) and (70.81,941.35) .. (68.47,942.07)
 .. controls (66.13,942.79) and (55.33,945.13) .. (48.67,948.01)
 .. controls (42.01,950.89) and (39.49,950.89) .. (34.45,954.85)
 .. controls (29.41,958.81) and (29.59,959.53) .. (27.61,963.67)
 .. controls (25.63,967.81) and (23.83,968.89) .. (24.55,973.39)
 .. controls (25.27,977.89) and (25.45,978.43) .. (26.35,979.33)
));
endfig;
beginfig(16);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char51 \mainfont{} etex,(336.61,-809.86),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char50 \mainfont{} etex,(-654.05,798.29),0.0,0);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char84 \char97 \char110 \char103 \char121 \ \char67 \char105 \char99 \char97 \char100 \char97 \mainfont{} etex,(353.89,-931.18),0.0,0);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char67 \char114 \char121 \char115 \char116 \char97 \char108 \ \char67 \char97 \char110 \char97 \char108 \char115 \mainfont{} etex,(-665.93,1126.25),0.0,0);
endfig;
background:=(0.37000,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.37000, 1.00000, 0.25000);
current_scrap := "romeoSP1@romeo_entrance.romeo";
ATTR__scrap := "romeoSP1";
beginfig(17);
current_src := "Romeo_entrance.th2 [725]";
string area_border[];
area_border[1] := "l173-10224-23120";
area_border[2] := "l177-10200-24128";
area_border[3] := "l588-10096-23664";
drawoptions();
a_clay(buildcycle(((453.45,749.51)
 .. controls (455.79,750.24) and (461.56,754.04) .. (465.52,755.85)
 .. controls (469.48,757.67) and (481.91,767.42) .. (484.25,769.77)
 .. controls (486.60,772.11) and (496.15,783.14) .. (500.29,788.56)
 .. controls (504.44,793.98) and (510.93,805.72) .. (513.45,810.40)
 .. controls (515.97,815.07) and (523.86,830.82) .. (525.65,833.67)
 .. controls (527.45,836.53) and (529.93,857.98) .. (530.46,862.99)
 .. controls (530.99,868.01) and (530.08,882.56) .. (530.09,890.85)
 .. controls (530.09,899.15) and (527.57,900.76) .. (526.67,903.28)
 .. controls (525.77,905.80) and (530.64,907.65) .. (531.54,908.56)
 .. controls (532.45,909.47) and (546.54,914.68) .. (547.80,915.06)
 .. controls (549.06,915.43) and (553.39,916.01) .. (555.56,917.47)
 .. controls (557.73,918.94) and (559.53,921.84) .. (560.08,922.75)
 .. controls (560.62,923.66) and (558.46,927.62) .. (557.92,929.42)
 .. controls (557.38,931.22) and (554.30,940.52) .. (554.30,943.73)
 .. controls (554.29,946.93) and (550.99,958.08) .. (547.90,962.65)
 .. controls (544.81,967.22) and (539.35,969.07) .. (527.64,979.53)
 .. controls (515.88,990.04) and (498.52,1000.75) .. (492.26,1003.21)
 .. controls (485.99,1005.67) and (476.86,1009.25) .. (472.73,1011.83)
 .. controls (468.61,1014.41) and (466.81,1014.96) .. (464.29,1015.67)
 .. controls (461.77,1016.39) and (462.29,1012.36) .. (460.84,1010.34)
 .. controls (459.38,1008.31) and (452.13,998.00) .. (445.95,985.76)
 .. controls (439.81,973.60) and (429.00,972.67) .. (425.03,971.23)
 .. controls (421.07,969.79) and (405.07,965.71) .. (398.43,963.44)
 .. controls (391.79,961.16) and (377.98,956.32) .. (373.14,956.02)
 .. controls (368.29,955.72) and (351.96,951.95) .. (349.81,951.24)
 .. controls (347.65,950.54) and (336.68,949.11) .. (333.97,948.75)
 .. controls (331.27,948.38) and (306.91,946.01) .. (304.75,945.63)
 .. controls (302.58,945.25) and (296.79,951.81) .. (296.79,951.81)
),
((489.36,896.44)
 .. controls (489.36,896.44) and (488.60,931.57) .. (485.71,947.35)
 .. controls (482.82,963.17) and (495.06,965.35) .. (497.23,977.59)
 .. controls (499.40,989.86) and (510.18,996.26) .. (510.18,996.26)
),
((489.36,896.44)
 -- (420.27,830.28)
 -- (296.79,951.81)
)));
current_src := "Romeo_entrance.th2 [645]";
string area_border[];
area_border[1] := "l601-8802-24326";
area_border[2] := "l173-10224-23120";
area_border[3] := "l602-9962-22858";
area_border[4] := "l169-9400-20832";
area_border[5] := "l603-8850-20564";
area_border[6] := "l606-8760-19828";
area_border[7] := "l181-8986-19593";
area_border[8] := "l685-9516-19820";
area_border[9] := "l6-9212-19400";
area_border[10] := "l6-9212-19400";
area_border[11] := "l604-9758-20332";
area_border[12] := "l597-10410-22954";
drawoptions();
a_water(buildcycle(((246.72,1009.84)
 .. controls (246.72,1009.84) and (228.28,961.22) .. (260.72,957.82)
 .. controls (293.18,954.42) and (296.79,951.81) .. (296.79,951.81)
),
((453.45,749.51)
 .. controls (455.79,750.24) and (461.56,754.04) .. (465.52,755.85)
 .. controls (469.48,757.67) and (481.91,767.42) .. (484.25,769.77)
 .. controls (486.60,772.11) and (496.15,783.14) .. (500.29,788.56)
 .. controls (504.44,793.98) and (510.93,805.72) .. (513.45,810.40)
 .. controls (515.97,815.07) and (523.86,830.82) .. (525.65,833.67)
 .. controls (527.45,836.53) and (529.93,857.98) .. (530.46,862.99)
 .. controls (530.99,868.01) and (530.08,882.56) .. (530.09,890.85)
 .. controls (530.09,899.15) and (527.57,900.76) .. (526.67,903.28)
 .. controls (525.77,905.80) and (530.64,907.65) .. (531.54,908.56)
 .. controls (532.45,909.47) and (546.54,914.68) .. (547.80,915.06)
 .. controls (549.06,915.43) and (553.39,916.01) .. (555.56,917.47)
 .. controls (557.73,918.94) and (559.53,921.84) .. (560.08,922.75)
 .. controls (560.62,923.66) and (558.46,927.62) .. (557.92,929.42)
 .. controls (557.38,931.22) and (554.30,940.52) .. (554.30,943.73)
 .. controls (554.29,946.93) and (550.99,958.08) .. (547.90,962.65)
 .. controls (544.81,967.22) and (539.35,969.07) .. (527.64,979.53)
 .. controls (515.88,990.04) and (498.52,1000.75) .. (492.26,1003.21)
 .. controls (485.99,1005.67) and (476.86,1009.25) .. (472.73,1011.83)
 .. controls (468.61,1014.41) and (466.81,1014.96) .. (464.29,1015.67)
 .. controls (461.77,1016.39) and (462.29,1012.36) .. (460.84,1010.34)
 .. controls (459.38,1008.31) and (452.13,998.00) .. (445.95,985.76)
 .. controls (439.81,973.60) and (429.00,972.67) .. (425.03,971.23)
 .. controls (421.07,969.79) and (405.07,965.71) .. (398.43,963.44)
 .. controls (391.79,961.16) and (377.98,956.32) .. (373.14,956.02)
 .. controls (368.29,955.72) and (351.96,951.95) .. (349.81,951.24)
 .. controls (347.65,950.54) and (336.68,949.11) .. (333.97,948.75)
 .. controls (331.27,948.38) and (306.91,946.01) .. (304.75,945.63)
 .. controls (302.58,945.25) and (296.79,951.81) .. (296.79,951.81)
),
((453.45,749.51)
 -- (419.43,668.87)
),
((256.40,342.51)
 .. controls (258.20,340.72) and (278.91,339.51) .. (287.56,340.06)
 .. controls (296.20,340.62) and (324.82,351.23) .. (331.30,355.72)
 .. controls (337.77,360.20) and (351.98,375.27) .. (356.84,380.30)
 .. controls (361.70,385.33) and (390.13,413.93) .. (393.37,417.53)
 .. controls (396.61,421.14) and (422.02,454.89) .. (425.45,463.90)
 .. controls (428.87,472.91) and (432.29,482.27) .. (431.92,486.76)
 .. controls (431.56,491.25) and (440.54,514.60) .. (442.16,520.16)
 .. controls (443.78,525.73) and (447.38,549.86) .. (449.00,554.01)
 .. controls (450.62,558.16) and (451.72,585.61) .. (450.28,589.76)
 .. controls (448.85,593.91) and (442.72,611.36) .. (441.46,615.31)
 .. controls (440.20,619.26) and (434.05,635.38) .. (432.25,638.78)
 .. controls (430.44,642.18) and (425.75,654.00) .. (423.94,655.25)
 .. controls (422.14,656.50) and (419.43,668.87) .. (419.43,668.87)
),
((256.40,342.51)
 -- (207.99,227.30)
),
((207.99,227.30)
 -- (241.49,170.67)
),
((342.67,138.17)
 .. controls (342.67,138.17) and (324.84,131.14) .. (322.32,131.13)
 .. controls (319.80,131.13) and (316.56,130.05) .. (311.70,131.31)
 .. controls (306.84,132.56) and (305.94,134.90) .. (303.78,138.14)
 .. controls (301.62,141.38) and (300.36,142.28) .. (297.66,147.33)
 .. controls (294.96,152.37) and (288.30,152.00) .. (282.54,150.02)
 .. controls (276.77,148.03) and (271.55,146.23) .. (265.79,147.12)
 .. controls (260.03,148.01) and (260.39,149.45) .. (256.07,151.79)
 .. controls (251.75,154.12) and (251.93,157.55) .. (250.49,161.32)
 .. controls (249.05,165.10) and (243.29,170.13) .. (241.49,170.67)
),
((342.67,138.17)
 -- (381.54,215.21)
),
((218.55,972.76)
 .. controls (259.64,965.73) and (291.73,959.81) .. (296.43,955.74)
 .. controls (301.12,951.67) and (311.80,944.10) .. (316.32,938.06)
 .. controls (320.84,932.01) and (331.48,919.12) .. (334.00,916.96)
 .. controls (336.52,914.80) and (339.58,914.27) .. (344.26,913.90)
 .. controls (348.94,913.54) and (353.61,912.06) .. (355.58,910.78)
 .. controls (357.55,909.50) and (371.89,898.86) .. (377.81,887.22)
 .. controls (383.72,875.61) and (395.41,868.35) .. (398.47,864.74)
 .. controls (401.53,861.14) and (409.63,853.77) .. (410.18,851.43)
 .. controls (410.72,849.10) and (415.94,844.08) .. (421.16,848.05)
 .. controls (426.38,852.02) and (441.87,859.79) .. (444.57,862.49)
 .. controls (447.27,865.19) and (458.23,878.28) .. (458.95,883.29)
 .. controls (459.66,888.30) and (469.54,906.58) .. (471.52,908.92)
 .. controls (473.50,911.25) and (475.29,918.07) .. (478.17,919.33)
 .. controls (481.05,920.60) and (498.53,926.43) .. (499.08,912.44)
 .. controls (499.63,898.45) and (497.48,889.12) .. (497.30,885.19)
 .. controls (497.13,881.25) and (497.89,862.16) .. (498.09,855.74)
 .. controls (498.29,849.33) and (497.96,836.66) .. (497.25,831.48)
 .. controls (496.54,826.28) and (495.28,814.78) .. (492.40,808.82)
 .. controls (489.51,802.85) and (483.19,789.80) .. (479.04,784.37)
 .. controls (474.89,778.94) and (468.22,774.94) .. (465.16,771.33)
 .. controls (462.09,767.71) and (460.47,764.47) .. (458.13,758.16)
 .. controls (455.79,751.86) and (455.80,734.95) .. (453.64,727.75)
 .. controls (451.47,720.55) and (446.97,707.03) .. (441.03,697.30)
 .. controls (435.09,687.58) and (420.87,662.41) .. (416.56,655.41)
 .. controls (412.24,648.40) and (402.89,634.02) .. (401.81,630.06)
 .. controls (400.73,626.11) and (389.20,615.82) .. (388.85,606.11)
 .. controls (388.49,596.39) and (386.33,574.24) .. (384.88,569.73)
 .. controls (383.44,565.23) and (377.87,531.74) .. (376.97,524.90)
 .. controls (376.07,518.06) and (369.96,490.54) .. (359.69,480.81)
 .. controls (349.43,471.08) and (331.25,446.78) .. (326.93,441.21)
 .. controls (322.61,435.63) and (299.03,417.11) .. (293.64,405.08)
 .. controls (288.25,393.04) and (279.79,374.00) .. (276.20,366.63)
 .. controls (272.60,359.26) and (259.28,343.96) .. (257.66,336.04)
 .. controls (256.04,328.13) and (252.45,307.61) .. (252.09,300.95)
 .. controls (251.73,294.29) and (251.37,273.78) .. (244.71,260.09)
 .. controls (238.05,246.41) and (236.26,225.18) .. (235.72,217.81)
 .. controls (235.18,210.43) and (237.52,180.20) .. (238.60,177.51)
 .. controls (239.68,174.81) and (240.23,178.05) .. (243.65,172.65)
 .. controls (247.07,167.26) and (249.59,156.64) .. (247.79,151.06)
 .. controls (245.99,145.48) and (241.66,124.04) .. (243.28,119.00)
 .. controls (244.90,113.96) and (247.96,96.49) .. (250.12,92.35)
 .. controls (252.28,88.21) and (251.91,70.19) .. (262.17,69.12)
 .. controls (272.44,68.05) and (280.36,70.58) .. (287.74,81.93)
 .. controls (295.13,93.29) and (302.69,100.14) .. (306.65,105.73)
 .. controls (310.62,111.32) and (318.90,122.85) .. (322.32,125.19)
 .. controls (325.74,127.54) and (325.74,132.58) .. (330.78,134.02)
 .. controls (335.82,135.46) and (339.79,137.81) .. (342.67,138.17)
),
((218.55,972.76)
 .. controls (259.64,965.73) and (291.73,959.81) .. (296.43,955.74)
 .. controls (301.12,951.67) and (311.80,944.10) .. (316.32,938.06)
 .. controls (320.84,932.01) and (331.48,919.12) .. (334.00,916.96)
 .. controls (336.52,914.80) and (339.58,914.27) .. (344.26,913.90)
 .. controls (348.94,913.54) and (353.61,912.06) .. (355.58,910.78)
 .. controls (357.55,909.50) and (371.89,898.86) .. (377.81,887.22)
 .. controls (383.72,875.61) and (395.41,868.35) .. (398.47,864.74)
 .. controls (401.53,861.14) and (409.63,853.77) .. (410.18,851.43)
 .. controls (410.72,849.10) and (415.94,844.08) .. (421.16,848.05)
 .. controls (426.38,852.02) and (441.87,859.79) .. (444.57,862.49)
 .. controls (447.27,865.19) and (458.23,878.28) .. (458.95,883.29)
 .. controls (459.66,888.30) and (469.54,906.58) .. (471.52,908.92)
 .. controls (473.50,911.25) and (475.29,918.07) .. (478.17,919.33)
 .. controls (481.05,920.60) and (498.53,926.43) .. (499.08,912.44)
 .. controls (499.63,898.45) and (497.48,889.12) .. (497.30,885.19)
 .. controls (497.13,881.25) and (497.89,862.16) .. (498.09,855.74)
 .. controls (498.29,849.33) and (497.96,836.66) .. (497.25,831.48)
 .. controls (496.54,826.28) and (495.28,814.78) .. (492.40,808.82)
 .. controls (489.51,802.85) and (483.19,789.80) .. (479.04,784.37)
 .. controls (474.89,778.94) and (468.22,774.94) .. (465.16,771.33)
 .. controls (462.09,767.71) and (460.47,764.47) .. (458.13,758.16)
 .. controls (455.79,751.86) and (455.80,734.95) .. (453.64,727.75)
 .. controls (451.47,720.55) and (446.97,707.03) .. (441.03,697.30)
 .. controls (435.09,687.58) and (420.87,662.41) .. (416.56,655.41)
 .. controls (412.24,648.40) and (402.89,634.02) .. (401.81,630.06)
 .. controls (400.73,626.11) and (389.20,615.82) .. (388.85,606.11)
 .. controls (388.49,596.39) and (386.33,574.24) .. (384.88,569.73)
 .. controls (383.44,565.23) and (377.87,531.74) .. (376.97,524.90)
 .. controls (376.07,518.06) and (369.96,490.54) .. (359.69,480.81)
 .. controls (349.43,471.08) and (331.25,446.78) .. (326.93,441.21)
 .. controls (322.61,435.63) and (299.03,417.11) .. (293.64,405.08)
 .. controls (288.25,393.04) and (279.79,374.00) .. (276.20,366.63)
 .. controls (272.60,359.26) and (259.28,343.96) .. (257.66,336.04)
 .. controls (256.04,328.13) and (252.45,307.61) .. (252.09,300.95)
 .. controls (251.73,294.29) and (251.37,273.78) .. (244.71,260.09)
 .. controls (238.05,246.41) and (236.26,225.18) .. (235.72,217.81)
 .. controls (235.18,210.43) and (237.52,180.20) .. (238.60,177.51)
 .. controls (239.68,174.81) and (240.23,178.05) .. (243.65,172.65)
 .. controls (247.07,167.26) and (249.59,156.64) .. (247.79,151.06)
 .. controls (245.99,145.48) and (241.66,124.04) .. (243.28,119.00)
 .. controls (244.90,113.96) and (247.96,96.49) .. (250.12,92.35)
 .. controls (252.28,88.21) and (251.91,70.19) .. (262.17,69.12)
 .. controls (272.44,68.05) and (280.36,70.58) .. (287.74,81.93)
 .. controls (295.13,93.29) and (302.69,100.14) .. (306.65,105.73)
 .. controls (310.62,111.32) and (318.90,122.85) .. (322.32,125.19)
 .. controls (325.74,127.54) and (325.74,132.58) .. (330.78,134.02)
 .. controls (335.82,135.46) and (339.79,137.81) .. (342.67,138.17)
),
((381.54,215.21)
 -- (467.18,411.62)
 -- (527.26,546.13)
 -- (528.36,676.89)
 -- (521.93,726.57)
),
((246.72,1009.84)
 .. controls (246.72,1009.84) and (311.08,947.07) .. (384.90,982.61)
 .. controls (459.45,1018.51) and (444.21,1037.64) .. (483.38,1027.94)
 .. controls (522.52,1018.25) and (563.20,971.01) .. (569.00,960.08)
 .. controls (574.82,949.10) and (593.12,899.17) .. (576.15,870.99)
 .. controls (559.27,842.95) and (554.60,791.59) .. (540.94,777.27)
 .. controls (527.28,762.95) and (525.16,736.80) .. (521.93,726.57)
)));
current_src := "Romeo_entrance.th2 [529]";
string area_border[];
area_border[1] := "l684-11582-29882";
drawoptions();
a_sand(buildcycle(((619.12,2006.80)
 .. controls (619.12,2006.80) and (710.58,2065.21) .. (714.16,2001.42)
 .. controls (717.74,1937.64) and (761.69,2045.74) .. (761.69,2045.74)
 -- (628.14,2092.92)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [490]";
string area_border[];
area_border[1] := "l638-10708-27500";
area_border[2] := "l209-10984-27732";
area_border[3] := "l643-11124-27794";
area_border[4] := "l640-11146-27756";
area_border[5] := "l211-10474-26546";
area_border[6] := "l213-10126-26710";
area_border[7] := "l638-10708-27500";
drawoptions();
a_water(buildcycle(((472.03,1479.72)
 -- (611.28,1593.92)
),
((645.35,1627.02)
 .. controls (645.35,1627.02) and (642.79,1626.16) .. (640.27,1624.37)
 .. controls (637.75,1622.58) and (639.19,1621.34) .. (636.50,1617.23)
 .. controls (633.81,1613.11) and (628.77,1610.05) .. (625.89,1607.52)
 .. controls (623.00,1604.99) and (621.02,1603.36) .. (619.58,1601.20)
 .. controls (618.14,1599.03) and (613.62,1595.21) .. (611.28,1593.92)
),
((659.71,1623.49)
 .. controls (652.44,1623.50) and (645.35,1627.02) .. (645.35,1627.02)
),
((565.40,1359.64)
 -- (668.19,1474.84)
 -- (659.71,1623.49)
),
((475.28,1372.90)
 .. controls (475.28,1372.90) and (474.89,1375.38) .. (478.24,1381.59)
 .. controls (481.59,1387.81) and (486.41,1397.35) .. (490.12,1399.86)
 .. controls (493.79,1402.37) and (499.54,1405.74) .. (506.66,1405.84)
 .. controls (513.63,1405.94) and (529.03,1406.09) .. (533.89,1401.01)
 .. controls (538.74,1395.95) and (546.13,1388.97) .. (549.10,1385.87)
 .. controls (552.07,1382.78) and (557.47,1374.57) .. (559.72,1371.86)
 .. controls (561.97,1369.15) and (565.40,1359.64) .. (565.40,1359.64)
),
((472.03,1479.72)
 .. controls (472.03,1479.72) and (463.08,1470.20) .. (461.38,1461.57)
 .. controls (459.66,1452.85) and (454.47,1449.39) .. (460.99,1443.81)
 .. controls (467.47,1438.27) and (467.94,1441.21) .. (472.89,1434.89)
 .. controls (477.89,1428.53) and (479.03,1425.25) .. (479.48,1418.32)
 .. controls (479.94,1411.34) and (480.69,1410.11) .. (484.83,1406.43)
 .. controls (488.97,1402.75) and (493.10,1398.65) .. (493.10,1398.65)
),
((472.03,1479.72)
 -- (611.28,1593.92)
)));
current_src := "Romeo_entrance.th2 [354]";
string area_border[];
area_border[1] := "l648-10804-28026";
area_border[2] := "l210-10833-28559";
area_border[3] := "l650-11042-28484";
area_border[4] := "l208-11076-27806";
area_border[5] := "l209-10984-27732";
drawoptions();
a_blocks(buildcycle(((577.33,1786.02)
 -- (611.28,1593.92)
),
((577.33,1786.02)
 .. controls (579.67,1783.87) and (587.23,1771.82) .. (588.68,1769.66)
 .. controls (590.12,1767.50) and (592.13,1764.37) .. (596.78,1761.94)
 .. controls (604.34,1758.00) and (596.78,1759.07) .. (608.30,1761.94)
 .. controls (611.90,1762.84) and (618.02,1760.85) .. (622.87,1762.10)
 .. controls (627.73,1763.36) and (634.57,1767.85) .. (634.57,1767.85)
),
((650.14,1665.84)
 .. controls (650.14,1665.84) and (650.74,1725.10) .. (634.57,1767.85)
),
((650.14,1665.84)
 .. controls (650.14,1665.84) and (647.08,1667.66) .. (642.41,1666.40)
 .. controls (637.73,1665.15) and (634.67,1663.17) .. (633.40,1656.49)
 .. controls (632.14,1649.82) and (631.77,1644.77) .. (633.58,1640.64)
 .. controls (635.38,1636.52) and (638.09,1633.84) .. (640.97,1630.80)
 .. controls (643.86,1627.77) and (647.47,1624.03) .. (652.15,1624.03)
 .. controls (656.83,1624.03) and (659.71,1623.49) .. (659.71,1623.49)
),
((645.35,1627.02)
 .. controls (645.35,1627.02) and (642.79,1626.16) .. (640.27,1624.37)
 .. controls (637.75,1622.58) and (639.19,1621.34) .. (636.50,1617.23)
 .. controls (633.81,1613.11) and (628.77,1610.05) .. (625.89,1607.52)
 .. controls (623.00,1604.99) and (621.02,1603.36) .. (619.58,1601.20)
 .. controls (618.14,1599.03) and (613.62,1595.21) .. (611.28,1593.92)
)));
current_src := "Romeo_entrance.th2 [306]";
string area_border[];
area_border[1] := "l210-10833-28559";
area_border[2] := "l646-10658-28742";
area_border[3] := "l213-10786-29310";
area_border[4] := "l645-11004-29038";
drawoptions();
a_water(buildcycle(((577.33,1786.02)
 .. controls (579.67,1783.87) and (587.23,1771.82) .. (588.68,1769.66)
 .. controls (590.12,1767.50) and (592.13,1764.37) .. (596.78,1761.94)
 .. controls (604.34,1758.00) and (596.78,1759.07) .. (608.30,1761.94)
 .. controls (611.90,1762.84) and (618.02,1760.85) .. (622.87,1762.10)
 .. controls (627.73,1763.36) and (634.57,1767.85) .. (634.57,1767.85)
),
((577.33,1786.02)
 .. controls (577.33,1786.02) and (540.58,1837.07) .. (580.42,1886.23)
),
((580.42,1886.23)
 .. controls (580.42,1886.23) and (588.35,1891.66) .. (590.87,1893.47)
 .. controls (593.39,1895.28) and (598.98,1899.08) .. (605.28,1899.08)
 .. controls (611.58,1899.09) and (609.96,1899.63) .. (614.10,1898.72)
 .. controls (618.24,1897.81) and (624.71,1898.16) .. (627.05,1893.47)
 .. controls (629.39,1888.78) and (635.15,1875.62) .. (635.15,1875.62)
),
((634.57,1767.85)
 -- (635.15,1875.62)
)));
current_src := "Romeo_entrance.th2 [276]";
string area_border[];
area_border[1] := "l6-10998-29848";
area_border[2] := "l5-11066-29995";
area_border[3] := "l7-11386-29954";
area_border[4] := "l6-10998-29848";
area_border[5] := "l289-10912-29738";
area_border[6] := "l213-10786-29310";
area_border[7] := "l290-11258-29489";
drawoptions();
a_sand(buildcycle(((635.32,2009.16)
 .. controls (631.00,1999.07) and (629.19,1989.87) .. (655.84,1963.25)
 .. controls (681.16,1937.95) and (695.62,1987.72) .. (695.62,1987.72)
),
((687.35,2027.92)
 .. controls (655.63,2025.52) and (639.65,2019.26) .. (635.32,2009.16)
),
((695.62,1987.72)
 .. controls (695.62,1987.72) and (719.13,2030.35) .. (687.35,2027.92)
),
((635.32,2009.16)
 .. controls (631.00,1999.07) and (629.19,1989.87) .. (655.84,1963.25)
 .. controls (681.16,1937.95) and (695.62,1987.72) .. (695.62,1987.72)
),
((580.42,1886.23)
 .. controls (582.40,1891.46) and (601.13,1920.66) .. (606.16,1932.34)
 .. controls (611.20,1944.01) and (621.81,1987.35) .. (623.79,1992.93)
 .. controls (625.77,1998.52) and (635.32,2009.16) .. (635.32,2009.16)
),
((580.42,1886.23)
 .. controls (580.42,1886.23) and (588.35,1891.66) .. (590.87,1893.47)
 .. controls (593.39,1895.28) and (598.98,1899.08) .. (605.28,1899.08)
 .. controls (611.58,1899.09) and (609.96,1899.63) .. (614.10,1898.72)
 .. controls (618.24,1897.81) and (624.71,1898.16) .. (627.05,1893.47)
 .. controls (629.39,1888.78) and (635.15,1875.62) .. (635.15,1875.62)
),
((635.15,1875.62)
 .. controls (635.15,1875.62) and (635.33,1882.47) .. (648.12,1895.28)
 .. controls (660.90,1908.09) and (676.74,1906.08) .. (680.33,1924.96)
 .. controls (683.92,1943.82) and (689.31,1964.49) .. (692.73,1967.19)
 .. controls (696.15,1969.89) and (693.63,1974.93) .. (695.62,1987.72)
)));
current_src := "Romeo_entrance.th2 [271]";
string area_border[];
area_border[1] := "l6-11026-27178";
area_border[2] := "l208-11076-27806";
drawoptions();
a_flowstone(buildcycle(((512.92,1244.06)
 .. controls (512.92,1244.06) and (511.75,1245.93) .. (510.25,1259.99)
 .. controls (509.34,1268.55) and (514.35,1276.44) .. (517.91,1283.33)
 .. controls (521.49,1290.28) and (538.42,1315.64) .. (544.67,1328.20)
 .. controls (550.87,1340.65) and (569.19,1370.35) .. (574.38,1374.69)
 .. controls (579.59,1379.03) and (594.68,1404.06) .. (597.36,1409.67)
 .. controls (600.04,1415.28) and (605.68,1441.12) .. (611.47,1456.79)
 .. controls (617.13,1472.11) and (629.85,1496.66) .. (633.42,1500.51)
 .. controls (637.00,1504.37) and (642.91,1521.33) .. (649.04,1534.56)
 .. controls (655.22,1547.90) and (656.18,1564.53) .. (657.28,1571.80)
 .. controls (658.37,1579.03) and (656.01,1595.89) .. (658.33,1604.26)
 .. controls (660.64,1612.62) and (653.19,1645.13) .. (652.29,1650.52)
 .. controls (651.39,1655.92) and (645.83,1674.35) .. (645.13,1689.01)
 .. controls (644.44,1703.66) and (639.42,1727.69) .. (637.81,1729.68)
 .. controls (636.19,1731.67) and (632.23,1746.08) .. (632.23,1749.31)
 .. controls (632.23,1752.55) and (631.87,1769.47) .. (630.08,1774.53)
 .. controls (628.28,1779.59) and (627.22,1794.78) .. (625.97,1803.82)
 .. controls (624.73,1812.85) and (627.24,1821.49) .. (628.14,1827.06)
 .. controls (629.04,1832.63) and (628.30,1854.00) .. (629.92,1861.74)
 .. controls (631.54,1869.49) and (631.37,1879.41) .. (633.17,1887.88)
 .. controls (634.97,1896.35) and (641.81,1898.88) .. (651.36,1903.04)
 .. controls (660.90,1907.19) and (671.87,1928.93) .. (674.39,1934.67)
 .. controls (676.90,1940.41) and (690.39,1968.99) .. (691.29,1974.39)
 .. controls (692.19,1979.79) and (709.13,2020.90) .. (712.02,2027.21)
 .. controls (714.90,2033.53) and (723.73,2044.89) .. (724.99,2050.11)
),
((650.14,1665.84)
 .. controls (650.14,1665.84) and (647.08,1667.66) .. (642.41,1666.40)
 .. controls (637.73,1665.15) and (634.67,1663.17) .. (633.40,1656.49)
 .. controls (632.14,1649.82) and (631.77,1644.77) .. (633.58,1640.64)
 .. controls (635.38,1636.52) and (638.09,1633.84) .. (640.97,1630.80)
 .. controls (643.86,1627.77) and (647.47,1624.03) .. (652.15,1624.03)
 .. controls (656.83,1624.03) and (659.71,1623.49) .. (659.71,1623.49)
)));
current_src := "Romeo_entrance.th2 [256]";
string area_border[];
area_border[1] := "l6-11026-27178";
area_border[2] := "l216-10266-25887";
area_border[3] := "l5-9716-25416";
area_border[4] := "l13-9659-26066";
area_border[5] := "l14-9757-26365";
area_border[6] := "l211-10474-26546";
drawoptions();
a_flowstone(buildcycle(((512.92,1244.06)
 .. controls (512.92,1244.06) and (511.75,1245.93) .. (510.25,1259.99)
 .. controls (509.34,1268.55) and (514.35,1276.44) .. (517.91,1283.33)
 .. controls (521.49,1290.28) and (538.42,1315.64) .. (544.67,1328.20)
 .. controls (550.87,1340.65) and (569.19,1370.35) .. (574.38,1374.69)
 .. controls (579.59,1379.03) and (594.68,1404.06) .. (597.36,1409.67)
 .. controls (600.04,1415.28) and (605.68,1441.12) .. (611.47,1456.79)
 .. controls (617.13,1472.11) and (629.85,1496.66) .. (633.42,1500.51)
 .. controls (637.00,1504.37) and (642.91,1521.33) .. (649.04,1534.56)
 .. controls (655.22,1547.90) and (656.18,1564.53) .. (657.28,1571.80)
 .. controls (658.37,1579.03) and (656.01,1595.89) .. (658.33,1604.26)
 .. controls (660.64,1612.62) and (653.19,1645.13) .. (652.29,1650.52)
 .. controls (651.39,1655.92) and (645.83,1674.35) .. (645.13,1689.01)
 .. controls (644.44,1703.66) and (639.42,1727.69) .. (637.81,1729.68)
 .. controls (636.19,1731.67) and (632.23,1746.08) .. (632.23,1749.31)
 .. controls (632.23,1752.55) and (631.87,1769.47) .. (630.08,1774.53)
 .. controls (628.28,1779.59) and (627.22,1794.78) .. (625.97,1803.82)
 .. controls (624.73,1812.85) and (627.24,1821.49) .. (628.14,1827.06)
 .. controls (629.04,1832.63) and (628.30,1854.00) .. (629.92,1861.74)
 .. controls (631.54,1869.49) and (631.37,1879.41) .. (633.17,1887.88)
 .. controls (634.97,1896.35) and (641.81,1898.88) .. (651.36,1903.04)
 .. controls (660.90,1907.19) and (671.87,1928.93) .. (674.39,1934.67)
 .. controls (676.90,1940.41) and (690.39,1968.99) .. (691.29,1974.39)
 .. controls (692.19,1979.79) and (709.13,2020.90) .. (712.02,2027.21)
 .. controls (714.90,2033.53) and (723.73,2044.89) .. (724.99,2050.11)
),
((486.79,1257.39)
 -- (504.46,1266.77)
 -- (515.42,1250.39)
),
((357.78,167.69)
 .. controls (357.78,167.69) and (345.54,180.10) .. (347.52,192.69)
 .. controls (349.50,205.29) and (357.24,222.93) .. (355.43,230.66)
 .. controls (353.63,238.40) and (351.11,246.67) .. (352.90,256.02)
 .. controls (354.70,265.38) and (359.02,284.09) .. (359.38,287.51)
 .. controls (359.74,290.93) and (358.30,310.37) .. (369.81,317.91)
 .. controls (381.33,325.45) and (396.44,344.31) .. (397.34,346.10)
 .. controls (398.24,347.90) and (420.91,373.97) .. (426.49,379.91)
 .. controls (432.07,385.85) and (452.96,413.25) .. (455.13,417.76)
 .. controls (457.29,422.28) and (481.07,465.35) .. (482.86,471.10)
 .. controls (484.66,476.85) and (489.15,494.27) .. (489.49,516.36)
 .. controls (489.84,538.48) and (488.23,558.47) .. (488.41,570.74)
 .. controls (488.60,583.00) and (488.78,601.55) .. (490.76,611.80)
 .. controls (492.73,622.03) and (504.05,661.03) .. (506.39,667.70)
 .. controls (508.74,674.38) and (517.05,698.25) .. (518.68,704.21)
 .. controls (520.30,710.17) and (520.67,719.01) .. (521.93,726.57)
 .. controls (523.18,734.11) and (528.21,741.27) .. (537.55,750.19)
 .. controls (546.89,759.12) and (566.47,785.77) .. (569.16,791.33)
 .. controls (571.85,796.88) and (590.71,838.84) .. (592.51,849.27)
 .. controls (594.31,859.72) and (600.30,903.64) .. (598.88,917.59)
 .. controls (597.46,931.49) and (587.33,963.51) .. (566.00,980.67)
 .. controls (544.68,997.82) and (489.28,1037.69) .. (484.79,1040.10)
 .. controls (480.31,1042.50) and (459.28,1058.96) .. (430.79,1045.73)
 .. controls (402.25,1032.48) and (381.21,1022.19) .. (377.97,1019.88)
 .. controls (374.74,1017.57) and (346.90,1000.21) .. (345.39,1040.58)
 .. controls (343.89,1081.08) and (341.92,1087.94) .. (343.89,1093.86)
 .. controls (345.87,1099.79) and (344.42,1110.05) .. (359.56,1120.36)
 .. controls (374.57,1130.58) and (390.46,1140.79) .. (391.52,1145.93)
 .. controls (392.57,1151.03) and (402.20,1196.07) .. (403.86,1204.03)
 .. controls (405.52,1212.01) and (408.35,1252.30) .. (409.08,1262.36)
),
((413.25,1285.32)
 .. controls (413.25,1285.32) and (408.02,1290.19) .. (404.94,1294.59)
 .. controls (401.89,1298.95) and (399.18,1302.05) .. (395.73,1305.14)
 .. controls (392.31,1308.22) and (388.60,1315.57) .. (389.70,1317.08)
 .. controls (390.80,1318.60) and (391.60,1320.53) .. (388.83,1324.95)
 .. controls (386.09,1329.31) and (381.48,1338.10) .. (388.67,1339.66)
 .. controls (395.73,1341.20) and (402.47,1347.44) .. (408.71,1344.48)
 .. controls (415.01,1341.49) and (416.33,1337.06) .. (416.33,1337.06)
),
((485.07,1367.10)
 .. controls (480.56,1369.17) and (472.64,1374.97) .. (467.36,1378.27)
 .. controls (462.03,1381.61) and (447.45,1386.14) .. (439.68,1386.92)
 .. controls (432.44,1387.64) and (421.68,1382.45) .. (416.33,1378.74)
 .. controls (411.04,1375.08) and (411.04,1370.87) .. (410.36,1366.34)
 .. controls (409.69,1361.82) and (405.89,1354.79) .. (405.55,1352.00)
 .. controls (405.22,1349.20) and (404.17,1343.57) .. (404.17,1343.57)
),
((475.28,1372.90)
 .. controls (475.28,1372.90) and (474.89,1375.38) .. (478.24,1381.59)
 .. controls (481.59,1387.81) and (486.41,1397.35) .. (490.12,1399.86)
 .. controls (493.79,1402.37) and (499.54,1405.74) .. (506.66,1405.84)
 .. controls (513.63,1405.94) and (529.03,1406.09) .. (533.89,1401.01)
 .. controls (538.74,1395.95) and (546.13,1388.97) .. (549.10,1385.87)
 .. controls (552.07,1382.78) and (557.47,1374.57) .. (559.72,1371.86)
 .. controls (561.97,1369.15) and (565.40,1359.64) .. (565.40,1359.64)
)));
current_src := "Romeo_entrance.th2 [240]";
string area_border[];
area_border[1] := "l586-9470-25910";
drawoptions();
a_clay(buildcycle(((270.67,1137.05)
 .. controls (270.67,1137.05) and (275.44,1112.29) .. (274.75,1108.32)
 .. controls (267.41,1066.23) and (359.51,1104.29) .. (359.51,1104.29)
 -- (400.64,1132.85)
 .. controls (400.64,1132.85) and (439.26,1150.59) .. (414.71,1232.56)
 .. controls (387.64,1322.98) and (324.78,1263.53) .. (324.78,1263.53)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [219]";
string area_border[];
area_border[1] := "l169-9400-20832";
area_border[2] := "l593-9608-22152";
drawoptions();
a_blocks(buildcycle(((256.40,342.51)
 .. controls (258.20,340.72) and (278.91,339.51) .. (287.56,340.06)
 .. controls (296.20,340.62) and (324.82,351.23) .. (331.30,355.72)
 .. controls (337.77,360.20) and (351.98,375.27) .. (356.84,380.30)
 .. controls (361.70,385.33) and (390.13,413.93) .. (393.37,417.53)
 .. controls (396.61,421.14) and (422.02,454.89) .. (425.45,463.90)
 .. controls (428.87,472.91) and (432.29,482.27) .. (431.92,486.76)
 .. controls (431.56,491.25) and (440.54,514.60) .. (442.16,520.16)
 .. controls (443.78,525.73) and (447.38,549.86) .. (449.00,554.01)
 .. controls (450.62,558.16) and (451.72,585.61) .. (450.28,589.76)
 .. controls (448.85,593.91) and (442.72,611.36) .. (441.46,615.31)
 .. controls (440.20,619.26) and (434.05,635.38) .. (432.25,638.78)
 .. controls (430.44,642.18) and (425.75,654.00) .. (423.94,655.25)
 .. controls (422.14,656.50) and (419.43,668.87) .. (419.43,668.87)
),
((419.43,668.87)
 .. controls (419.43,668.87) and (237.12,365.12) .. (256.40,342.51)
)));
current_src := "Romeo_entrance.th2 [208]";
string area_border[];
area_border[1] := "l181-8986-19593";
area_border[2] := "l595-8816-19340";
drawoptions();
a_sand(buildcycle(((342.67,138.17)
 .. controls (342.67,138.17) and (324.84,131.14) .. (322.32,131.13)
 .. controls (319.80,131.13) and (316.56,130.05) .. (311.70,131.31)
 .. controls (306.84,132.56) and (305.94,134.90) .. (303.78,138.14)
 .. controls (301.62,141.38) and (300.36,142.28) .. (297.66,147.33)
 .. controls (294.96,152.37) and (288.30,152.00) .. (282.54,150.02)
 .. controls (276.77,148.03) and (271.55,146.23) .. (265.79,147.12)
 .. controls (260.03,148.01) and (260.39,149.45) .. (256.07,151.79)
 .. controls (251.75,154.12) and (251.93,157.55) .. (250.49,161.32)
 .. controls (249.05,165.10) and (243.29,170.13) .. (241.49,170.67)
),
((241.49,170.67)
 .. controls (241.49,170.67) and (225.22,-56.15) .. (342.67,138.17)
)));
current_src := "Romeo_entrance.th2 [106]";
string area_border[];
area_border[1] := "l5-11066-29995";
area_border[2] := "l6-10998-29848";
area_border[3] := "l7-11386-29954";
drawoptions();
a_pebbles(buildcycle(((687.35,2027.92)
 .. controls (655.63,2025.52) and (639.65,2019.26) .. (635.32,2009.16)
),
((635.32,2009.16)
 .. controls (631.00,1999.07) and (629.19,1989.87) .. (655.84,1963.25)
 .. controls (681.16,1937.95) and (695.62,1987.72) .. (695.62,1987.72)
),
((695.62,1987.72)
 .. controls (695.62,1987.72) and (719.13,2030.35) .. (687.35,2027.92)
)));
current_src := "Romeo_entrance.th2 [15]";
string area_border[];
area_border[1] := "l177-10200-24128";
area_border[2] := "l173-10224-23120";
area_border[3] := "l591-10140-23538";
drawoptions();
a_blocks(buildcycle(((489.36,896.44)
 .. controls (489.36,896.44) and (488.60,931.57) .. (485.71,947.35)
 .. controls (482.82,963.17) and (495.06,965.35) .. (497.23,977.59)
 .. controls (499.40,989.86) and (510.18,996.26) .. (510.18,996.26)
),
((453.45,749.51)
 .. controls (455.79,750.24) and (461.56,754.04) .. (465.52,755.85)
 .. controls (469.48,757.67) and (481.91,767.42) .. (484.25,769.77)
 .. controls (486.60,772.11) and (496.15,783.14) .. (500.29,788.56)
 .. controls (504.44,793.98) and (510.93,805.72) .. (513.45,810.40)
 .. controls (515.97,815.07) and (523.86,830.82) .. (525.65,833.67)
 .. controls (527.45,836.53) and (529.93,857.98) .. (530.46,862.99)
 .. controls (530.99,868.01) and (530.08,882.56) .. (530.09,890.85)
 .. controls (530.09,899.15) and (527.57,900.76) .. (526.67,903.28)
 .. controls (525.77,905.80) and (530.64,907.65) .. (531.54,908.56)
 .. controls (532.45,909.47) and (546.54,914.68) .. (547.80,915.06)
 .. controls (549.06,915.43) and (553.39,916.01) .. (555.56,917.47)
 .. controls (557.73,918.94) and (559.53,921.84) .. (560.08,922.75)
 .. controls (560.62,923.66) and (558.46,927.62) .. (557.92,929.42)
 .. controls (557.38,931.22) and (554.30,940.52) .. (554.30,943.73)
 .. controls (554.29,946.93) and (550.99,958.08) .. (547.90,962.65)
 .. controls (544.81,967.22) and (539.35,969.07) .. (527.64,979.53)
 .. controls (515.88,990.04) and (498.52,1000.75) .. (492.26,1003.21)
 .. controls (485.99,1005.67) and (476.86,1009.25) .. (472.73,1011.83)
 .. controls (468.61,1014.41) and (466.81,1014.96) .. (464.29,1015.67)
 .. controls (461.77,1016.39) and (462.29,1012.36) .. (460.84,1010.34)
 .. controls (459.38,1008.31) and (452.13,998.00) .. (445.95,985.76)
 .. controls (439.81,973.60) and (429.00,972.67) .. (425.03,971.23)
 .. controls (421.07,969.79) and (405.07,965.71) .. (398.43,963.44)
 .. controls (391.79,961.16) and (377.98,956.32) .. (373.14,956.02)
 .. controls (368.29,955.72) and (351.96,951.95) .. (349.81,951.24)
 .. controls (347.65,950.54) and (336.68,949.11) .. (333.97,948.75)
 .. controls (331.27,948.38) and (306.91,946.01) .. (304.75,945.63)
 .. controls (302.58,945.25) and (296.79,951.81) .. (296.79,951.81)
),
((489.36,896.44)
 -- (453.45,749.51)
)));
ATTR__id := "l159-9404-24340";
ATTR__height := -1;
drawoptions();
l_border_invisible(((368.24,1027.56)
 .. controls (368.24,1027.56) and (343.14,996.32) .. (335.97,990.64)
 .. controls (328.79,984.95) and (299.33,944.14) .. (300.79,924.04)
));
ATTR__id := "l177-10200-24128";
ATTR__height := -1;
drawoptions();
l_border_invisible(((489.36,896.44)
 .. controls (489.36,896.44) and (488.60,931.57) .. (485.71,947.35)
 .. controls (482.82,963.17) and (495.06,965.35) .. (497.23,977.59)
 .. controls (499.40,989.86) and (510.18,996.26) .. (510.18,996.26)
));
ATTR__id := "l588-10096-23664";
ATTR__height := -1;
drawoptions();
l_border_visible(((489.36,896.44)
 -- (420.27,830.28)
 -- (296.79,951.81)
));
ATTR__id := "l179-10084-22912";
ATTR__height := -1;
drawoptions();
l_border_invisible(((452.00,760.65)
 -- (469.31,745.62)
));
ATTR__id := "l181-8986-19593";
ATTR__height := -1;
drawoptions();
l_border_invisible(((342.67,138.17)
 .. controls (342.67,138.17) and (324.84,131.14) .. (322.32,131.13)
 .. controls (319.80,131.13) and (316.56,130.05) .. (311.70,131.31)
 .. controls (306.84,132.56) and (305.94,134.90) .. (303.78,138.14)
 .. controls (301.62,141.38) and (300.36,142.28) .. (297.66,147.33)
 .. controls (294.96,152.37) and (288.30,152.00) .. (282.54,150.02)
 .. controls (276.77,148.03) and (271.55,146.23) .. (265.79,147.12)
 .. controls (260.03,148.01) and (260.39,149.45) .. (256.07,151.79)
 .. controls (251.75,154.12) and (251.93,157.55) .. (250.49,161.32)
 .. controls (249.05,165.10) and (243.29,170.13) .. (241.49,170.67)
));
ATTR__id := "l173-10224-23120";
ATTR__height := -1;
drawoptions();
l_border_invisible(((453.45,749.51)
 .. controls (455.79,750.24) and (461.56,754.04) .. (465.52,755.85)
 .. controls (469.48,757.67) and (481.91,767.42) .. (484.25,769.77)
 .. controls (486.60,772.11) and (496.15,783.14) .. (500.29,788.56)
 .. controls (504.44,793.98) and (510.93,805.72) .. (513.45,810.40)
 .. controls (515.97,815.07) and (523.86,830.82) .. (525.65,833.67)
 .. controls (527.45,836.53) and (529.93,857.98) .. (530.46,862.99)
 .. controls (530.99,868.01) and (530.08,882.56) .. (530.09,890.85)
 .. controls (530.09,899.15) and (527.57,900.76) .. (526.67,903.28)
 .. controls (525.77,905.80) and (530.64,907.65) .. (531.54,908.56)
 .. controls (532.45,909.47) and (546.54,914.68) .. (547.80,915.06)
 .. controls (549.06,915.43) and (553.39,916.01) .. (555.56,917.47)
 .. controls (557.73,918.94) and (559.53,921.84) .. (560.08,922.75)
 .. controls (560.62,923.66) and (558.46,927.62) .. (557.92,929.42)
 .. controls (557.38,931.22) and (554.30,940.52) .. (554.30,943.73)
 .. controls (554.29,946.93) and (550.99,958.08) .. (547.90,962.65)
 .. controls (544.81,967.22) and (539.35,969.07) .. (527.64,979.53)
 .. controls (515.88,990.04) and (498.52,1000.75) .. (492.26,1003.21)
 .. controls (485.99,1005.67) and (476.86,1009.25) .. (472.73,1011.83)
 .. controls (468.61,1014.41) and (466.81,1014.96) .. (464.29,1015.67)
 .. controls (461.77,1016.39) and (462.29,1012.36) .. (460.84,1010.34)
 .. controls (459.38,1008.31) and (452.13,998.00) .. (445.95,985.76)
 .. controls (439.81,973.60) and (429.00,972.67) .. (425.03,971.23)
 .. controls (421.07,969.79) and (405.07,965.71) .. (398.43,963.44)
 .. controls (391.79,961.16) and (377.98,956.32) .. (373.14,956.02)
 .. controls (368.29,955.72) and (351.96,951.95) .. (349.81,951.24)
 .. controls (347.65,950.54) and (336.68,949.11) .. (333.97,948.75)
 .. controls (331.27,948.38) and (306.91,946.01) .. (304.75,945.63)
 .. controls (302.58,945.25) and (296.79,951.81) .. (296.79,951.81)
));
ATTR__id := "l163-9132-20000";
ATTR__height := -1;
drawoptions();
l_border_invisible(((207.99,227.30)
 -- (381.54,215.21)
));
ATTR__id := "l604-9758-20332";
ATTR__height := -1;
drawoptions();
l_border_invisible(((381.54,215.21)
 -- (467.18,411.62)
 -- (527.26,546.13)
 -- (528.36,676.89)
 -- (521.93,726.57)
));
ATTR__id := "l685-9516-19820";
ATTR__height := -1;
drawoptions();
l_border_invisible(((342.67,138.17)
 -- (381.54,215.21)
));
ATTR__id := "l606-8760-19828";
ATTR__height := -1;
drawoptions();
l_border_invisible(((207.99,227.30)
 -- (241.49,170.67)
));
ATTR__id := "l169-9400-20832";
ATTR__height := -1;
drawoptions();
l_border_invisible(((256.40,342.51)
 .. controls (258.20,340.72) and (278.91,339.51) .. (287.56,340.06)
 .. controls (296.20,340.62) and (324.82,351.23) .. (331.30,355.72)
 .. controls (337.77,360.20) and (351.98,375.27) .. (356.84,380.30)
 .. controls (361.70,385.33) and (390.13,413.93) .. (393.37,417.53)
 .. controls (396.61,421.14) and (422.02,454.89) .. (425.45,463.90)
 .. controls (428.87,472.91) and (432.29,482.27) .. (431.92,486.76)
 .. controls (431.56,491.25) and (440.54,514.60) .. (442.16,520.16)
 .. controls (443.78,525.73) and (447.38,549.86) .. (449.00,554.01)
 .. controls (450.62,558.16) and (451.72,585.61) .. (450.28,589.76)
 .. controls (448.85,593.91) and (442.72,611.36) .. (441.46,615.31)
 .. controls (440.20,619.26) and (434.05,635.38) .. (432.25,638.78)
 .. controls (430.44,642.18) and (425.75,654.00) .. (423.94,655.25)
 .. controls (422.14,656.50) and (419.43,668.87) .. (419.43,668.87)
));
ATTR__id := "l684-11582-29882";
ATTR__height := -1;
drawoptions();
l_border_invisible(((619.12,2006.80)
 .. controls (619.12,2006.80) and (710.58,2065.21) .. (714.16,2001.42)
 .. controls (717.74,1937.64) and (761.69,2045.74) .. (761.69,2045.74)
 -- (628.14,2092.92)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((544.89,1320.97)
 .. controls (544.89,1320.97) and (534.95,1331.42) .. (530.44,1333.65)
 .. controls (525.90,1335.89) and (519.87,1337.69) .. (515.34,1339.62)
 .. controls (510.79,1341.55) and (507.38,1343.95) .. (500.96,1344.69)
 .. controls (494.54,1345.44) and (488.52,1349.20) .. (484.01,1342.98)
 .. controls (479.52,1336.78) and (478.76,1327.24) .. (478.37,1321.44)
 .. controls (477.98,1315.65) and (478.69,1307.79) .. (479.77,1302.03)
 .. controls (480.84,1296.30) and (479.46,1283.47) .. (479.46,1283.47)
));
ATTR__id := "l638-10708-27500";
ATTR__height := -1;
drawoptions();
l_border_visible(((472.03,1479.72)
 -- (611.28,1593.92)
));
ATTR__id := "l640-11146-27756";
ATTR__height := -1;
drawoptions();
l_border_visible(((565.40,1359.64)
 -- (668.19,1474.84)
 -- (659.71,1623.49)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((506.63,1343.54)
 .. controls (506.63,1343.54) and (507.34,1352.33) .. (509.94,1355.74)
 .. controls (512.53,1359.16) and (518.02,1364.76) .. (522.05,1365.35)
 .. controls (526.05,1365.94) and (531.02,1368.26) .. (539.32,1365.82)
 .. controls (547.53,1363.41) and (551.05,1362.82) .. (554.21,1362.20)
 .. controls (557.36,1361.58) and (566.06,1355.21) .. (566.06,1355.21)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((488.52,1345.46)
 .. controls (488.52,1345.46) and (487.38,1350.46) .. (482.49,1352.98)
 .. controls (477.60,1355.50) and (471.71,1361.59) .. (463.72,1356.22)
 .. controls (455.88,1350.95) and (457.31,1353.39) .. (454.62,1346.02)
 .. controls (451.97,1338.75) and (451.57,1334.37) .. (450.79,1329.24)
 .. controls (450.01,1324.12) and (447.65,1324.34) .. (447.65,1319.02)
));
ATTR__id := "l14-9757-26365";
ATTR__height := -1;
drawoptions();
l_flowstone(((485.07,1367.10)
 .. controls (480.56,1369.17) and (472.64,1374.97) .. (467.36,1378.27)
 .. controls (462.03,1381.61) and (447.45,1386.14) .. (439.68,1386.92)
 .. controls (432.44,1387.64) and (421.68,1382.45) .. (416.33,1378.74)
 .. controls (411.04,1375.08) and (411.04,1370.87) .. (410.36,1366.34)
 .. controls (409.69,1361.82) and (405.89,1354.79) .. (405.55,1352.00)
 .. controls (405.22,1349.20) and (404.17,1343.57) .. (404.17,1343.57)
));
ATTR__id := "l13-9659-26066";
ATTR__height := -1;
drawoptions();
l_flowstone(((413.25,1285.32)
 .. controls (413.25,1285.32) and (408.02,1290.19) .. (404.94,1294.59)
 .. controls (401.89,1298.95) and (399.18,1302.05) .. (395.73,1305.14)
 .. controls (392.31,1308.22) and (388.60,1315.57) .. (389.70,1317.08)
 .. controls (390.80,1318.60) and (391.60,1320.53) .. (388.83,1324.95)
 .. controls (386.09,1329.31) and (381.48,1338.10) .. (388.67,1339.66)
 .. controls (395.73,1341.20) and (402.47,1347.44) .. (408.71,1344.48)
 .. controls (415.01,1341.49) and (416.33,1337.06) .. (416.33,1337.06)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((418.73,1310.36)
 .. controls (419.01,1326.54) and (421.91,1334.06) .. (424.07,1335.87)
 .. controls (426.22,1337.67) and (430.23,1337.35) .. (430.23,1337.35)
 .. controls (430.23,1337.35) and (428.05,1346.46) .. (428.77,1352.04)
 .. controls (429.48,1357.62) and (437.88,1369.75) .. (451.01,1357.98)
 .. controls (463.02,1347.21) and (458.44,1351.67) .. (458.44,1351.67)
));
ATTR__id := "l211-10474-26546";
ATTR__height := -1;
drawoptions();
l_flowstone(((475.28,1372.90)
 .. controls (475.28,1372.90) and (474.89,1375.38) .. (478.24,1381.59)
 .. controls (481.59,1387.81) and (486.41,1397.35) .. (490.12,1399.86)
 .. controls (493.79,1402.37) and (499.54,1405.74) .. (506.66,1405.84)
 .. controls (513.63,1405.94) and (529.03,1406.09) .. (533.89,1401.01)
 .. controls (538.74,1395.95) and (546.13,1388.97) .. (549.10,1385.87)
 .. controls (552.07,1382.78) and (557.47,1374.57) .. (559.72,1371.86)
 .. controls (561.97,1369.15) and (565.40,1359.64) .. (565.40,1359.64)
));
ATTR__id := "l213-10126-26710";
ATTR__height := -1;
drawoptions();
l_border_invisible(((472.03,1479.72)
 .. controls (472.03,1479.72) and (463.08,1470.20) .. (461.38,1461.57)
 .. controls (459.66,1452.85) and (454.47,1449.39) .. (460.99,1443.81)
 .. controls (467.47,1438.27) and (467.94,1441.21) .. (472.89,1434.89)
 .. controls (477.89,1428.53) and (479.03,1425.25) .. (479.48,1418.32)
 .. controls (479.94,1411.34) and (480.69,1410.11) .. (484.83,1406.43)
 .. controls (488.97,1402.75) and (493.10,1398.65) .. (493.10,1398.65)
));
ATTR__id := "l208-11076-27806";
ATTR__height := -1;
drawoptions();
l_flowstone(((650.14,1665.84)
 .. controls (650.14,1665.84) and (647.08,1667.66) .. (642.41,1666.40)
 .. controls (637.73,1665.15) and (634.67,1663.17) .. (633.40,1656.49)
 .. controls (632.14,1649.82) and (631.77,1644.77) .. (633.58,1640.64)
 .. controls (635.38,1636.52) and (638.09,1633.84) .. (640.97,1630.80)
 .. controls (643.86,1627.77) and (647.47,1624.03) .. (652.15,1624.03)
 .. controls (656.83,1624.03) and (659.71,1623.49) .. (659.71,1623.49)
));
ATTR__id := "l209-10984-27732";
ATTR__height := -1;
drawoptions();
l_border_invisible(((645.35,1627.02)
 .. controls (645.35,1627.02) and (642.79,1626.16) .. (640.27,1624.37)
 .. controls (637.75,1622.58) and (639.19,1621.34) .. (636.50,1617.23)
 .. controls (633.81,1613.11) and (628.77,1610.05) .. (625.89,1607.52)
 .. controls (623.00,1604.99) and (621.02,1603.36) .. (619.58,1601.20)
 .. controls (618.14,1599.03) and (613.62,1595.21) .. (611.28,1593.92)
));
ATTR__id := "l643-11124-27794";
ATTR__height := -1;
drawoptions();
l_border_invisible(((659.71,1623.49)
 .. controls (652.44,1623.50) and (645.35,1627.02) .. (645.35,1627.02)
));
ATTR__id := "l210-10833-28559";
ATTR__height := -1;
drawoptions();
l_border_invisible(((577.33,1786.02)
 .. controls (579.67,1783.87) and (587.23,1771.82) .. (588.68,1769.66)
 .. controls (590.12,1767.50) and (592.13,1764.37) .. (596.78,1761.94)
 .. controls (604.34,1758.00) and (596.78,1759.07) .. (608.30,1761.94)
 .. controls (611.90,1762.84) and (618.02,1760.85) .. (622.87,1762.10)
 .. controls (627.73,1763.36) and (634.57,1767.85) .. (634.57,1767.85)
));
ATTR__id := "l648-10804-28026";
ATTR__height := -1;
drawoptions();
l_border_invisible(((577.33,1786.02)
 -- (611.28,1593.92)
));
ATTR__id := "l650-11042-28484";
ATTR__height := -1;
drawoptions();
l_border_invisible(((650.14,1665.84)
 .. controls (650.14,1665.84) and (650.74,1725.10) .. (634.57,1767.85)
));
ATTR__id := "l645-11004-29038";
ATTR__height := -1;
drawoptions();
l_border_invisible(((634.57,1767.85)
 -- (635.15,1875.62)
));
ATTR__id := "l213-10786-29310";
ATTR__height := -1;
drawoptions();
l_border_invisible(((580.42,1886.23)
 .. controls (580.42,1886.23) and (588.35,1891.66) .. (590.87,1893.47)
 .. controls (593.39,1895.28) and (598.98,1899.08) .. (605.28,1899.08)
 .. controls (611.58,1899.09) and (609.96,1899.63) .. (614.10,1898.72)
 .. controls (618.24,1897.81) and (624.71,1898.16) .. (627.05,1893.47)
 .. controls (629.39,1888.78) and (635.15,1875.62) .. (635.15,1875.62)
));
ATTR__id := "l646-10658-28742";
ATTR__height := -1;
drawoptions();
l_border_invisible(((577.33,1786.02)
 .. controls (577.33,1786.02) and (540.58,1837.07) .. (580.42,1886.23)
));
ATTR__id := "l290-11258-29489";
ATTR__height := -1;
drawoptions();
l_border_visible(((635.15,1875.62)
 .. controls (635.15,1875.62) and (635.33,1882.47) .. (648.12,1895.28)
 .. controls (660.90,1908.09) and (676.74,1906.08) .. (680.33,1924.96)
 .. controls (683.92,1943.82) and (689.31,1964.49) .. (692.73,1967.19)
 .. controls (696.15,1969.89) and (693.63,1974.93) .. (695.62,1987.72)
));
ATTR__id := "l289-10912-29738";
ATTR__height := -1;
drawoptions();
l_border_visible(((580.42,1886.23)
 .. controls (582.40,1891.46) and (601.13,1920.66) .. (606.16,1932.34)
 .. controls (611.20,1944.01) and (621.81,1987.35) .. (623.79,1992.93)
 .. controls (625.77,1998.52) and (635.32,2009.16) .. (635.32,2009.16)
));
ATTR__id := "l216-10266-25887";
ATTR__height := -1;
drawoptions();
l_border_invisible(((486.79,1257.39)
 -- (504.46,1266.77)
 -- (515.42,1250.39)
));
ATTR__id := "l586-9470-25910";
ATTR__height := -1;
drawoptions();
l_border_invisible(((270.67,1137.05)
 .. controls (270.67,1137.05) and (275.44,1112.29) .. (274.75,1108.32)
 .. controls (267.41,1066.23) and (359.51,1104.29) .. (359.51,1104.29)
 -- (400.64,1132.85)
 .. controls (400.64,1132.85) and (439.26,1150.59) .. (414.71,1232.56)
 .. controls (387.64,1322.98) and (324.78,1263.53) .. (324.78,1263.53)
 -- cycle
));
ATTR__id := "l588-8912-24928";
ATTR__height := -1;
drawoptions();
l_border_invisible(((256.82,1098.13)
 .. controls (256.82,1098.13) and (238.01,991.54) .. (289.90,978.43)
 .. controls (346.58,964.12) and (318.21,1014.70) .. (325.48,1031.49)
 .. controls (333.35,1049.70) and (342.96,1069.60) .. (313.61,1080.50)
 .. controls (259.03,1100.78) and (304.21,1127.53) .. (267.88,1113.99)
 .. controls (265.84,1113.23) and (256.82,1098.13) .. cycle
));
ATTR__id := "l593-9608-22152";
ATTR__height := -1;
drawoptions();
l_border_invisible(((419.43,668.87)
 .. controls (419.43,668.87) and (237.12,365.12) .. (256.40,342.51)
));
ATTR__id := "l595-8816-19340";
ATTR__height := -1;
drawoptions();
l_border_invisible(((241.49,170.67)
 .. controls (241.49,170.67) and (225.22,-56.15) .. (342.67,138.17)
));
ATTR__id := "l597-10410-22954";
ATTR__height := -1;
drawoptions();
l_border_invisible(((246.72,1009.84)
 .. controls (246.72,1009.84) and (311.08,947.07) .. (384.90,982.61)
 .. controls (459.45,1018.51) and (444.21,1037.64) .. (483.38,1027.94)
 .. controls (522.52,1018.25) and (563.20,971.01) .. (569.00,960.08)
 .. controls (574.82,949.10) and (593.12,899.17) .. (576.15,870.99)
 .. controls (559.27,842.95) and (554.60,791.59) .. (540.94,777.27)
 .. controls (527.28,762.95) and (525.16,736.80) .. (521.93,726.57)
));
ATTR__id := "l601-8802-24326";
ATTR__height := -1;
drawoptions();
l_border_invisible(((246.72,1009.84)
 .. controls (246.72,1009.84) and (228.28,961.22) .. (260.72,957.82)
 .. controls (293.18,954.42) and (296.79,951.81) .. (296.79,951.81)
));
ATTR__id := "l602-9962-22858";
ATTR__height := -1;
drawoptions();
l_border_invisible(((453.45,749.51)
 -- (419.43,668.87)
));
ATTR__id := "l603-8850-20564";
ATTR__height := -1;
drawoptions();
l_border_invisible(((256.40,342.51)
 -- (207.99,227.30)
));
ATTR__id := "l7-11386-29954";
ATTR__height := -1;
drawoptions();
l_floorstep(((695.62,1987.72)
 .. controls (695.62,1987.72) and (719.13,2030.35) .. (687.35,2027.92)
));
ATTR__id := "l6-10998-29848";
ATTR__height := -1;
drawoptions();
l_floorstep(((635.32,2009.16)
 .. controls (631.00,1999.07) and (629.19,1989.87) .. (655.84,1963.25)
 .. controls (681.16,1937.95) and (695.62,1987.72) .. (695.62,1987.72)
));
ATTR__id := "l5-11066-29995";
ATTR__height := -1;
drawoptions();
l_floorstep(((687.35,2027.92)
 .. controls (655.63,2025.52) and (639.65,2019.26) .. (635.32,2009.16)
));
ATTR__id := "l591-10140-23538";
ATTR__height := -1;
drawoptions();
l_border_visible(((489.36,896.44)
 -- (453.45,749.51)
));
endfig;
beginfig(18);
draw_upscrap(1)(1,((357.78,167.69)
 .. controls (357.78,167.69) and (345.54,180.10) .. (347.52,192.69)
 .. controls (349.50,205.29) and (357.24,222.93) .. (355.43,230.66)
 .. controls (353.63,238.40) and (351.11,246.67) .. (352.90,256.02)
 .. controls (354.70,265.38) and (359.02,284.09) .. (359.38,287.51)
 .. controls (359.74,290.93) and (358.30,310.37) .. (369.81,317.91)
 .. controls (381.33,325.45) and (396.44,344.31) .. (397.34,346.10)
 .. controls (398.24,347.90) and (420.91,373.97) .. (426.49,379.91)
 .. controls (432.07,385.85) and (452.96,413.25) .. (455.13,417.76)
 .. controls (457.29,422.28) and (481.07,465.35) .. (482.86,471.10)
 .. controls (484.66,476.85) and (489.15,494.27) .. (489.49,516.36)
 .. controls (489.84,538.48) and (488.23,558.47) .. (488.41,570.74)
 .. controls (488.60,583.00) and (488.78,601.55) .. (490.76,611.80)
 .. controls (492.73,622.03) and (504.05,661.03) .. (506.39,667.70)
 .. controls (508.74,674.38) and (517.05,698.25) .. (518.68,704.21)
 .. controls (520.30,710.17) and (520.67,719.01) .. (521.93,726.57)
 .. controls (523.18,734.11) and (528.21,741.27) .. (537.55,750.19)
 .. controls (546.89,759.12) and (566.47,785.77) .. (569.16,791.33)
 .. controls (571.85,796.88) and (590.71,838.84) .. (592.51,849.27)
 .. controls (594.31,859.72) and (600.30,903.64) .. (598.88,917.59)
 .. controls (597.46,931.49) and (587.33,963.51) .. (566.00,980.67)
 .. controls (544.68,997.82) and (489.28,1037.69) .. (484.79,1040.10)
 .. controls (480.31,1042.50) and (459.28,1058.96) .. (430.79,1045.73)
 .. controls (402.25,1032.48) and (381.21,1022.19) .. (377.97,1019.88)
 .. controls (374.74,1017.57) and (346.90,1000.21) .. (345.39,1040.58)
 .. controls (343.89,1081.08) and (341.92,1087.94) .. (343.89,1093.86)
 .. controls (345.87,1099.79) and (344.42,1110.05) .. (359.56,1120.36)
 .. controls (374.57,1130.58) and (390.46,1140.79) .. (391.52,1145.93)
 .. controls (392.57,1151.03) and (402.20,1196.07) .. (403.86,1204.03)
 .. controls (405.52,1212.01) and (408.35,1252.30) .. (409.08,1262.36)
),
1,((409.08,1262.36)
 .. controls (409.86,1272.61) and (411.80,1301.84) .. (414.03,1306.40)
 .. controls (416.25,1310.93) and (417.64,1332.55) .. (436.25,1323.11)
 .. controls (456.13,1313.03) and (461.46,1311.20) .. (463.90,1308.93)
 .. controls (466.32,1306.69) and (475.76,1295.83) .. (476.83,1292.15)
 .. controls (477.90,1288.50) and (479.16,1287.24) .. (483.06,1284.60)
 .. controls (486.96,1281.97) and (492.01,1281.79) .. (493.67,1278.28)
 .. controls (495.32,1274.81) and (497.05,1272.98) .. (495.33,1267.18)
 .. controls (493.13,1259.73) and (493.18,1258.70) .. (489.40,1254.14)
),
1,((512.92,1244.06)
 .. controls (512.92,1244.06) and (511.75,1245.93) .. (510.25,1259.99)
 .. controls (509.34,1268.55) and (514.35,1276.44) .. (517.91,1283.33)
 .. controls (521.49,1290.28) and (538.42,1315.64) .. (544.67,1328.20)
 .. controls (550.87,1340.65) and (569.19,1370.35) .. (574.38,1374.69)
 .. controls (579.59,1379.03) and (594.68,1404.06) .. (597.36,1409.67)
 .. controls (600.04,1415.28) and (605.68,1441.12) .. (611.47,1456.79)
 .. controls (617.13,1472.11) and (629.85,1496.66) .. (633.42,1500.51)
 .. controls (637.00,1504.37) and (642.91,1521.33) .. (649.04,1534.56)
 .. controls (655.22,1547.90) and (656.18,1564.53) .. (657.28,1571.80)
 .. controls (658.37,1579.03) and (656.01,1595.89) .. (658.33,1604.26)
 .. controls (660.64,1612.62) and (653.19,1645.13) .. (652.29,1650.52)
 .. controls (651.39,1655.92) and (645.83,1674.35) .. (645.13,1689.01)
 .. controls (644.44,1703.66) and (639.42,1727.69) .. (637.81,1729.68)
 .. controls (636.19,1731.67) and (632.23,1746.08) .. (632.23,1749.31)
 .. controls (632.23,1752.55) and (631.87,1769.47) .. (630.08,1774.53)
 .. controls (628.28,1779.59) and (627.22,1794.78) .. (625.97,1803.82)
 .. controls (624.73,1812.85) and (627.24,1821.49) .. (628.14,1827.06)
 .. controls (629.04,1832.63) and (628.30,1854.00) .. (629.92,1861.74)
 .. controls (631.54,1869.49) and (631.37,1879.41) .. (633.17,1887.88)
 .. controls (634.97,1896.35) and (641.81,1898.88) .. (651.36,1903.04)
 .. controls (660.90,1907.19) and (671.87,1928.93) .. (674.39,1934.67)
 .. controls (676.90,1940.41) and (690.39,1968.99) .. (691.29,1974.39)
 .. controls (692.19,1979.79) and (709.13,2020.90) .. (712.02,2027.21)
 .. controls (714.90,2033.53) and (723.73,2044.89) .. (724.99,2050.11)
),
1,((645.43,2071.89)
 .. controls (643.81,2066.67) and (641.10,2053.51) .. (640.56,2043.42)
 .. controls (640.01,2033.33) and (635.50,2006.82) .. (632.80,2001.41)
 .. controls (630.10,1996.00) and (617.49,1962.52) .. (616.23,1954.79)
 .. controls (614.98,1947.07) and (610.84,1935.39) .. (611.02,1932.16)
 .. controls (611.21,1928.93) and (610.49,1920.13) .. (602.22,1911.68)
 .. controls (593.93,1903.21) and (580.42,1886.23) .. (575.18,1863.49)
 .. controls (569.96,1840.78) and (563.47,1829.05) .. (565.81,1822.76)
 .. controls (568.16,1816.46) and (565.99,1816.63) .. (568.88,1815.20)
 .. controls (571.76,1813.77) and (572.30,1812.51) .. (573.56,1806.21)
 .. controls (574.82,1799.90) and (581.11,1785.14) .. (581.65,1778.11)
 .. controls (582.19,1771.09) and (586.70,1759.78) .. (585.99,1749.74)
 .. controls (585.28,1739.70) and (587.09,1737.02) .. (588.53,1734.52)
 .. controls (589.97,1732.01) and (589.80,1726.09) .. (589.62,1720.15)
 .. controls (589.44,1714.20) and (591.06,1714.21) .. (591.60,1712.58)
 .. controls (592.13,1710.96) and (594.29,1705.71) .. (595.36,1701.55)
 .. controls (596.43,1697.37) and (599.96,1674.28) .. (602.83,1670.46)
 .. controls (605.70,1666.65) and (611.96,1640.59) .. (613.04,1634.11)
 .. controls (614.13,1627.65) and (614.16,1602.92) .. (615.24,1600.61)
 .. controls (616.33,1598.29) and (619.05,1591.16) .. (617.97,1587.91)
 .. controls (616.88,1584.66) and (610.72,1570.11) .. (607.83,1567.17)
 .. controls (604.93,1564.23) and (590.83,1545.44) .. (587.76,1539.64)
 .. controls (584.69,1533.85) and (571.70,1517.70) .. (567.37,1513.67)
 .. controls (563.02,1509.64) and (544.06,1503.21) .. (535.21,1501.01)
 .. controls (526.39,1498.82) and (505.21,1492.28) .. (501.62,1489.29)
 .. controls (498.05,1486.32) and (450.83,1465.32) .. (445.99,1459.16)
 .. controls (441.16,1453.01) and (404.58,1411.89) .. (400.60,1402.33)
 .. controls (396.69,1392.93) and (385.35,1368.67) .. (383.65,1363.43)
 .. controls (381.94,1358.15) and (382.35,1354.36) .. (380.22,1352.11)
 .. controls (378.07,1349.83) and (373.00,1348.70) .. (369.22,1343.41)
 .. controls (365.37,1338.01) and (354.13,1310.19) .. (352.25,1305.98)
),
1,((352.25,1305.98)
 .. controls (350.38,1301.79) and (340.55,1269.30) .. (338.57,1261.90)
 .. controls (336.61,1254.58) and (330.42,1222.80) .. (328.54,1216.62)
 .. controls (326.65,1210.45) and (322.42,1189.79) .. (319.58,1184.51)
 .. controls (316.71,1179.18) and (298.09,1152.94) .. (294.65,1147.29)
 .. controls (291.22,1141.66) and (279.88,1131.55) .. (273.94,1126.74)
 .. controls (268.03,1121.94) and (215.56,1073.69) .. (206.72,1066.21)
),
1,((206.72,1066.21)
 -- (206.72,1066.21)),
1,((218.55,972.76)
 .. controls (259.64,965.73) and (291.73,959.81) .. (296.43,955.74)
 .. controls (301.12,951.67) and (311.80,944.10) .. (316.32,938.06)
 .. controls (320.84,932.01) and (331.48,919.12) .. (334.00,916.96)
 .. controls (336.52,914.80) and (339.58,914.27) .. (344.26,913.90)
 .. controls (348.94,913.54) and (353.61,912.06) .. (355.58,910.78)
 .. controls (357.55,909.50) and (371.89,898.86) .. (377.81,887.22)
 .. controls (383.72,875.61) and (395.41,868.35) .. (398.47,864.74)
 .. controls (401.53,861.14) and (409.63,853.77) .. (410.18,851.43)
 .. controls (410.72,849.10) and (415.94,844.08) .. (421.16,848.05)
 .. controls (426.38,852.02) and (441.87,859.79) .. (444.57,862.49)
 .. controls (447.27,865.19) and (458.23,878.28) .. (458.95,883.29)
 .. controls (459.66,888.30) and (469.54,906.58) .. (471.52,908.92)
 .. controls (473.50,911.25) and (475.29,918.07) .. (478.17,919.33)
 .. controls (481.05,920.60) and (498.53,926.43) .. (499.08,912.44)
 .. controls (499.63,898.45) and (497.48,889.12) .. (497.30,885.19)
 .. controls (497.13,881.25) and (497.89,862.16) .. (498.09,855.74)
 .. controls (498.29,849.33) and (497.96,836.66) .. (497.25,831.48)
 .. controls (496.54,826.28) and (495.28,814.78) .. (492.40,808.82)
 .. controls (489.51,802.85) and (483.19,789.80) .. (479.04,784.37)
 .. controls (474.89,778.94) and (468.22,774.94) .. (465.16,771.33)
 .. controls (462.09,767.71) and (460.47,764.47) .. (458.13,758.16)
 .. controls (455.79,751.86) and (455.80,734.95) .. (453.64,727.75)
 .. controls (451.47,720.55) and (446.97,707.03) .. (441.03,697.30)
 .. controls (435.09,687.58) and (420.87,662.41) .. (416.56,655.41)
 .. controls (412.24,648.40) and (402.89,634.02) .. (401.81,630.06)
 .. controls (400.73,626.11) and (389.20,615.82) .. (388.85,606.11)
 .. controls (388.49,596.39) and (386.33,574.24) .. (384.88,569.73)
 .. controls (383.44,565.23) and (377.87,531.74) .. (376.97,524.90)
 .. controls (376.07,518.06) and (369.96,490.54) .. (359.69,480.81)
 .. controls (349.43,471.08) and (331.25,446.78) .. (326.93,441.21)
 .. controls (322.61,435.63) and (299.03,417.11) .. (293.64,405.08)
 .. controls (288.25,393.04) and (279.79,374.00) .. (276.20,366.63)
 .. controls (272.60,359.26) and (259.28,343.96) .. (257.66,336.04)
 .. controls (256.04,328.13) and (252.45,307.61) .. (252.09,300.95)
 .. controls (251.73,294.29) and (251.37,273.78) .. (244.71,260.09)
 .. controls (238.05,246.41) and (236.26,225.18) .. (235.72,217.81)
 .. controls (235.18,210.43) and (237.52,180.20) .. (238.60,177.51)
 .. controls (239.68,174.81) and (240.23,178.05) .. (243.65,172.65)
 .. controls (247.07,167.26) and (249.59,156.64) .. (247.79,151.06)
 .. controls (245.99,145.48) and (241.66,124.04) .. (243.28,119.00)
 .. controls (244.90,113.96) and (247.96,96.49) .. (250.12,92.35)
 .. controls (252.28,88.21) and (251.91,70.19) .. (262.17,69.12)
 .. controls (272.44,68.05) and (280.36,70.58) .. (287.74,81.93)
 .. controls (295.13,93.29) and (302.69,100.14) .. (306.65,105.73)
 .. controls (310.62,111.32) and (318.90,122.85) .. (322.32,125.19)
 .. controls (325.74,127.54) and (325.74,132.58) .. (330.78,134.02)
 .. controls (335.82,135.46) and (339.79,137.81) .. (342.67,138.17)
));
draw_upscrap(1)(1,((461.84,1456.52)
 -- (461.84,1456.52)));
draw_downscrap;
endfig;
beginfig(19);
ATTR__id := "";
current_src := "Romeo_entrance.th2 [169]";
string area_border[];
area_border[1] := "l588-8912-24928";
drawoptions();
a_blocks(buildcycle(((256.82,1098.13)
 .. controls (256.82,1098.13) and (238.01,991.54) .. (289.90,978.43)
 .. controls (346.58,964.12) and (318.21,1014.70) .. (325.48,1031.49)
 .. controls (333.35,1049.70) and (342.96,1069.60) .. (313.61,1080.50)
 .. controls (259.03,1100.78) and (304.21,1127.53) .. (267.88,1113.99)
 .. controls (265.84,1113.23) and (256.82,1098.13) .. cycle
)));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((409.08,1262.36)
 .. controls (409.86,1272.61) and (411.80,1301.84) .. (414.03,1306.40)
 .. controls (416.25,1310.93) and (417.64,1332.55) .. (436.25,1323.11)
 .. controls (456.13,1313.03) and (461.46,1311.20) .. (463.90,1308.93)
 .. controls (466.32,1306.69) and (475.76,1295.83) .. (476.83,1292.15)
 .. controls (477.90,1288.50) and (479.16,1287.24) .. (483.06,1284.60)
 .. controls (486.96,1281.97) and (492.01,1281.79) .. (493.67,1278.28)
 .. controls (495.32,1274.81) and (497.05,1272.98) .. (495.33,1267.18)
 .. controls (493.13,1259.73) and (493.18,1258.70) .. (489.40,1254.14)
));
ATTR__id := "l5-9716-25416";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((357.78,167.69)
 .. controls (357.78,167.69) and (345.54,180.10) .. (347.52,192.69)
 .. controls (349.50,205.29) and (357.24,222.93) .. (355.43,230.66)
 .. controls (353.63,238.40) and (351.11,246.67) .. (352.90,256.02)
 .. controls (354.70,265.38) and (359.02,284.09) .. (359.38,287.51)
 .. controls (359.74,290.93) and (358.30,310.37) .. (369.81,317.91)
 .. controls (381.33,325.45) and (396.44,344.31) .. (397.34,346.10)
 .. controls (398.24,347.90) and (420.91,373.97) .. (426.49,379.91)
 .. controls (432.07,385.85) and (452.96,413.25) .. (455.13,417.76)
 .. controls (457.29,422.28) and (481.07,465.35) .. (482.86,471.10)
 .. controls (484.66,476.85) and (489.15,494.27) .. (489.49,516.36)
 .. controls (489.84,538.48) and (488.23,558.47) .. (488.41,570.74)
 .. controls (488.60,583.00) and (488.78,601.55) .. (490.76,611.80)
 .. controls (492.73,622.03) and (504.05,661.03) .. (506.39,667.70)
 .. controls (508.74,674.38) and (517.05,698.25) .. (518.68,704.21)
 .. controls (520.30,710.17) and (520.67,719.01) .. (521.93,726.57)
 .. controls (523.18,734.11) and (528.21,741.27) .. (537.55,750.19)
 .. controls (546.89,759.12) and (566.47,785.77) .. (569.16,791.33)
 .. controls (571.85,796.88) and (590.71,838.84) .. (592.51,849.27)
 .. controls (594.31,859.72) and (600.30,903.64) .. (598.88,917.59)
 .. controls (597.46,931.49) and (587.33,963.51) .. (566.00,980.67)
 .. controls (544.68,997.82) and (489.28,1037.69) .. (484.79,1040.10)
 .. controls (480.31,1042.50) and (459.28,1058.96) .. (430.79,1045.73)
 .. controls (402.25,1032.48) and (381.21,1022.19) .. (377.97,1019.88)
 .. controls (374.74,1017.57) and (346.90,1000.21) .. (345.39,1040.58)
 .. controls (343.89,1081.08) and (341.92,1087.94) .. (343.89,1093.86)
 .. controls (345.87,1099.79) and (344.42,1110.05) .. (359.56,1120.36)
 .. controls (374.57,1130.58) and (390.46,1140.79) .. (391.52,1145.93)
 .. controls (392.57,1151.03) and (402.20,1196.07) .. (403.86,1204.03)
 .. controls (405.52,1212.01) and (408.35,1252.30) .. (409.08,1262.36)
));
ATTR__id := "l6-11026-27178";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((512.92,1244.06)
 .. controls (512.92,1244.06) and (511.75,1245.93) .. (510.25,1259.99)
 .. controls (509.34,1268.55) and (514.35,1276.44) .. (517.91,1283.33)
 .. controls (521.49,1290.28) and (538.42,1315.64) .. (544.67,1328.20)
 .. controls (550.87,1340.65) and (569.19,1370.35) .. (574.38,1374.69)
 .. controls (579.59,1379.03) and (594.68,1404.06) .. (597.36,1409.67)
 .. controls (600.04,1415.28) and (605.68,1441.12) .. (611.47,1456.79)
 .. controls (617.13,1472.11) and (629.85,1496.66) .. (633.42,1500.51)
 .. controls (637.00,1504.37) and (642.91,1521.33) .. (649.04,1534.56)
 .. controls (655.22,1547.90) and (656.18,1564.53) .. (657.28,1571.80)
 .. controls (658.37,1579.03) and (656.01,1595.89) .. (658.33,1604.26)
 .. controls (660.64,1612.62) and (653.19,1645.13) .. (652.29,1650.52)
 .. controls (651.39,1655.92) and (645.83,1674.35) .. (645.13,1689.01)
 .. controls (644.44,1703.66) and (639.42,1727.69) .. (637.81,1729.68)
 .. controls (636.19,1731.67) and (632.23,1746.08) .. (632.23,1749.31)
 .. controls (632.23,1752.55) and (631.87,1769.47) .. (630.08,1774.53)
 .. controls (628.28,1779.59) and (627.22,1794.78) .. (625.97,1803.82)
 .. controls (624.73,1812.85) and (627.24,1821.49) .. (628.14,1827.06)
 .. controls (629.04,1832.63) and (628.30,1854.00) .. (629.92,1861.74)
 .. controls (631.54,1869.49) and (631.37,1879.41) .. (633.17,1887.88)
 .. controls (634.97,1896.35) and (641.81,1898.88) .. (651.36,1903.04)
 .. controls (660.90,1907.19) and (671.87,1928.93) .. (674.39,1934.67)
 .. controls (676.90,1940.41) and (690.39,1968.99) .. (691.29,1974.39)
 .. controls (692.19,1979.79) and (709.13,2020.90) .. (712.02,2027.21)
 .. controls (714.90,2033.53) and (723.73,2044.89) .. (724.99,2050.11)
));
ATTR__id := "";
drawoptions();
p_stalagmite((580.39,1499.90),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((598.76,1529.83),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((613.92,1544.74),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((526.55,783.44),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((457.53,1409.69),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((434.72,1400.75),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((416.45,1408.27),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((430.73,1425.30),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((472.37,1416.62),0.0,1.00,(0,0));
drawoptions();
p_stalactites((446.18,1441.55),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((361.83,1001.22),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((494.90,794.71),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((570.76,823.85),0.0,1.00,(0,0));
drawoptions();
p_stalactite((582.27,870.25),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((352.25,1305.98)
 .. controls (350.38,1301.79) and (340.55,1269.30) .. (338.57,1261.90)
 .. controls (336.61,1254.58) and (330.42,1222.80) .. (328.54,1216.62)
 .. controls (326.65,1210.45) and (322.42,1189.79) .. (319.58,1184.51)
 .. controls (316.71,1179.18) and (298.09,1152.94) .. (294.65,1147.29)
 .. controls (291.22,1141.66) and (279.88,1131.55) .. (273.94,1126.74)
 .. controls (268.03,1121.94) and (215.56,1073.69) .. (206.72,1066.21)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((645.43,2071.89)
 .. controls (643.81,2066.67) and (641.10,2053.51) .. (640.56,2043.42)
 .. controls (640.01,2033.33) and (635.50,2006.82) .. (632.80,2001.41)
 .. controls (630.10,1996.00) and (617.49,1962.52) .. (616.23,1954.79)
 .. controls (614.98,1947.07) and (610.84,1935.39) .. (611.02,1932.16)
 .. controls (611.21,1928.93) and (610.49,1920.13) .. (602.22,1911.68)
 .. controls (593.93,1903.21) and (580.42,1886.23) .. (575.18,1863.49)
 .. controls (569.96,1840.78) and (563.47,1829.05) .. (565.81,1822.76)
 .. controls (568.16,1816.46) and (565.99,1816.63) .. (568.88,1815.20)
 .. controls (571.76,1813.77) and (572.30,1812.51) .. (573.56,1806.21)
 .. controls (574.82,1799.90) and (581.11,1785.14) .. (581.65,1778.11)
 .. controls (582.19,1771.09) and (586.70,1759.78) .. (585.99,1749.74)
 .. controls (585.28,1739.70) and (587.09,1737.02) .. (588.53,1734.52)
 .. controls (589.97,1732.01) and (589.80,1726.09) .. (589.62,1720.15)
 .. controls (589.44,1714.20) and (591.06,1714.21) .. (591.60,1712.58)
 .. controls (592.13,1710.96) and (594.29,1705.71) .. (595.36,1701.55)
 .. controls (596.43,1697.37) and (599.96,1674.28) .. (602.83,1670.46)
 .. controls (605.70,1666.65) and (611.96,1640.59) .. (613.04,1634.11)
 .. controls (614.13,1627.65) and (614.16,1602.92) .. (615.24,1600.61)
 .. controls (616.33,1598.29) and (619.05,1591.16) .. (617.97,1587.91)
 .. controls (616.88,1584.66) and (610.72,1570.11) .. (607.83,1567.17)
 .. controls (604.93,1564.23) and (590.83,1545.44) .. (587.76,1539.64)
 .. controls (584.69,1533.85) and (571.70,1517.70) .. (567.37,1513.67)
 .. controls (563.02,1509.64) and (544.06,1503.21) .. (535.21,1501.01)
 .. controls (526.39,1498.82) and (505.21,1492.28) .. (501.62,1489.29)
 .. controls (498.05,1486.32) and (450.83,1465.32) .. (445.99,1459.16)
 .. controls (441.16,1453.01) and (404.58,1411.89) .. (400.60,1402.33)
 .. controls (396.69,1392.93) and (385.35,1368.67) .. (383.65,1363.43)
 .. controls (381.94,1358.15) and (382.35,1354.36) .. (380.22,1352.11)
 .. controls (378.07,1349.83) and (373.00,1348.70) .. (369.22,1343.41)
 .. controls (365.37,1338.01) and (354.13,1310.19) .. (352.25,1305.98)
));
ATTR__id := "l6-9212-19400";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((218.55,972.76)
 .. controls (259.64,965.73) and (291.73,959.81) .. (296.43,955.74)
 .. controls (301.12,951.67) and (311.80,944.10) .. (316.32,938.06)
 .. controls (320.84,932.01) and (331.48,919.12) .. (334.00,916.96)
 .. controls (336.52,914.80) and (339.58,914.27) .. (344.26,913.90)
 .. controls (348.94,913.54) and (353.61,912.06) .. (355.58,910.78)
 .. controls (357.55,909.50) and (371.89,898.86) .. (377.81,887.22)
 .. controls (383.72,875.61) and (395.41,868.35) .. (398.47,864.74)
 .. controls (401.53,861.14) and (409.63,853.77) .. (410.18,851.43)
 .. controls (410.72,849.10) and (415.94,844.08) .. (421.16,848.05)
 .. controls (426.38,852.02) and (441.87,859.79) .. (444.57,862.49)
 .. controls (447.27,865.19) and (458.23,878.28) .. (458.95,883.29)
 .. controls (459.66,888.30) and (469.54,906.58) .. (471.52,908.92)
 .. controls (473.50,911.25) and (475.29,918.07) .. (478.17,919.33)
 .. controls (481.05,920.60) and (498.53,926.43) .. (499.08,912.44)
 .. controls (499.63,898.45) and (497.48,889.12) .. (497.30,885.19)
 .. controls (497.13,881.25) and (497.89,862.16) .. (498.09,855.74)
 .. controls (498.29,849.33) and (497.96,836.66) .. (497.25,831.48)
 .. controls (496.54,826.28) and (495.28,814.78) .. (492.40,808.82)
 .. controls (489.51,802.85) and (483.19,789.80) .. (479.04,784.37)
 .. controls (474.89,778.94) and (468.22,774.94) .. (465.16,771.33)
 .. controls (462.09,767.71) and (460.47,764.47) .. (458.13,758.16)
 .. controls (455.79,751.86) and (455.80,734.95) .. (453.64,727.75)
 .. controls (451.47,720.55) and (446.97,707.03) .. (441.03,697.30)
 .. controls (435.09,687.58) and (420.87,662.41) .. (416.56,655.41)
 .. controls (412.24,648.40) and (402.89,634.02) .. (401.81,630.06)
 .. controls (400.73,626.11) and (389.20,615.82) .. (388.85,606.11)
 .. controls (388.49,596.39) and (386.33,574.24) .. (384.88,569.73)
 .. controls (383.44,565.23) and (377.87,531.74) .. (376.97,524.90)
 .. controls (376.07,518.06) and (369.96,490.54) .. (359.69,480.81)
 .. controls (349.43,471.08) and (331.25,446.78) .. (326.93,441.21)
 .. controls (322.61,435.63) and (299.03,417.11) .. (293.64,405.08)
 .. controls (288.25,393.04) and (279.79,374.00) .. (276.20,366.63)
 .. controls (272.60,359.26) and (259.28,343.96) .. (257.66,336.04)
 .. controls (256.04,328.13) and (252.45,307.61) .. (252.09,300.95)
 .. controls (251.73,294.29) and (251.37,273.78) .. (244.71,260.09)
 .. controls (238.05,246.41) and (236.26,225.18) .. (235.72,217.81)
 .. controls (235.18,210.43) and (237.52,180.20) .. (238.60,177.51)
 .. controls (239.68,174.81) and (240.23,178.05) .. (243.65,172.65)
 .. controls (247.07,167.26) and (249.59,156.64) .. (247.79,151.06)
 .. controls (245.99,145.48) and (241.66,124.04) .. (243.28,119.00)
 .. controls (244.90,113.96) and (247.96,96.49) .. (250.12,92.35)
 .. controls (252.28,88.21) and (251.91,70.19) .. (262.17,69.12)
 .. controls (272.44,68.05) and (280.36,70.58) .. (287.74,81.93)
 .. controls (295.13,93.29) and (302.69,100.14) .. (306.65,105.73)
 .. controls (310.62,111.32) and (318.90,122.85) .. (322.32,125.19)
 .. controls (325.74,127.54) and (325.74,132.58) .. (330.78,134.02)
 .. controls (335.82,135.46) and (339.79,137.81) .. (342.67,138.17)
));
endfig;
background:=(1.00000,0.25000,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.25000, 0.25000);
current_scrap := "romeoSP0@romeo_entrance.romeo";
ATTR__scrap := "romeoSP0";
beginfig(20);
ATTR__id := "";
current_src := "Romeo_entrance.th2 [3907]";
string area_border[];
area_border[1] := "l2-3472-6720";
drawoptions();
a_water(buildcycle(((-196.15,142.60)
 .. controls (-198.13,143.32) and (-199.75,142.60) .. (-202.99,143.14)
 .. controls (-206.23,143.68) and (-212.17,143.68) .. (-217.21,143.86)
 .. controls (-222.25,144.04) and (-226.03,142.42) .. (-233.23,140.26)
 .. controls (-240.43,138.10) and (-237.73,135.22) .. (-244.57,125.50)
 .. controls (-251.41,115.78) and (-242.41,101.92) .. (-247.99,89.32)
 .. controls (-253.57,76.72) and (-248.35,76.00) .. (-251.05,63.58)
 .. controls (-253.76,51.16) and (-252.32,44.68) .. (-251.42,31.35)
 .. controls (-250.52,18.03) and (-249.62,17.13) .. (-249.62,5.43)
 .. controls (-249.62,-6.27) and (-249.62,1.83) .. (-247.64,-4.65)
 .. controls (-245.66,-11.13) and (-244.40,-6.63) .. (-241.16,-7.53)
 .. controls (-237.92,-8.43) and (-233.96,-8.97) .. (-231.80,-8.61)
 .. controls (-229.64,-8.25) and (-224.24,-5.73) .. (-219.02,-4.11)
 .. controls (-213.80,-2.49) and (-213.80,0.57) .. (-210.02,7.06)
 .. controls (-206.24,13.54) and (-205.88,23.98) .. (-201.20,30.28)
 .. controls (-196.51,36.58) and (-194.35,47.02) .. (-192.01,52.42)
 .. controls (-189.67,57.82) and (-184.45,62.68) .. (-179.77,68.98)
 .. controls (-175.09,75.28) and (-173.47,83.20) .. (-171.49,89.14)
 .. controls (-169.51,95.08) and (-168.25,96.52) .. (-171.13,99.22)
 .. controls (-174.01,101.92) and (-176.71,97.60) .. (-181.21,99.22)
 .. controls (-185.71,100.84) and (-180.85,101.56) .. (-181.39,112.36)
 .. controls (-181.93,123.16) and (-177.79,126.76) .. (-179.23,133.78)
 .. controls (-180.67,140.80) and (-194.17,141.88) .. cycle
)));
current_src := "Romeo_entrance.th2 [3808]";
string area_border[];
area_border[1] := "l86-5372-7218";
area_border[2] := "l217-5828-7294";
area_border[3] := "l87-5698-7070";
area_border[4] := "l218-5044-6636";
drawoptions();
a_blocks(buildcycle(((280.32,318.82)
 .. controls (276.18,313.96) and (272.94,311.08) .. (266.82,307.30)
 .. controls (260.70,303.53) and (258.72,305.15) .. (253.50,304.07)
 .. controls (248.28,302.99) and (241.08,298.85) .. (237.30,293.63)
 .. controls (233.51,288.41) and (226.49,284.81) .. (225.05,279.95)
 .. controls (223.61,275.09) and (227.21,270.77) .. (218.93,262.31)
 .. controls (210.65,253.85) and (201.83,245.57) .. (197.69,242.33)
 .. controls (193.55,239.09) and (187.97,231.17) .. (181.13,226.49)
 .. controls (174.29,221.81) and (159.53,213.53) .. (155.39,208.31)
 .. controls (151.25,203.09) and (143.33,196.97) .. (140.27,191.93)
 .. controls (137.21,186.89) and (127.67,175.37) .. (121.91,171.59)
 .. controls (116.15,167.81) and (108.77,163.85) .. (102.29,157.91)
 .. controls (95.81,151.97) and (86.45,144.95) .. (79.97,141.35)
 .. controls (73.49,137.75) and (60.71,129.29) .. (54.41,122.27)
 .. controls (48.11,115.25) and (43.25,106.25) .. (36.77,101.93)
 .. controls (30.29,97.61) and (18.59,90.23) .. (11.57,79.79)
 .. controls (4.55,69.35) and (0.77,59.45) .. (-2.83,57.29)
 .. controls (-6.43,55.13) and (-18.85,49.18) .. (-22.09,45.22)
 .. controls (-25.33,41.26) and (-47.10,24.52) .. (-49.44,19.84)
 .. controls (-51.78,15.16) and (-66.90,-4.82) .. (-69.96,-9.86)
 .. controls (-73.02,-14.90) and (-76.98,-23.90) .. (-86.16,-26.60)
 .. controls (-95.34,-29.30) and (-104.16,-26.42) .. (-112.44,-33.44)
 .. controls (-120.72,-40.46) and (-126.84,-45.86) .. (-128.28,-47.84)
 .. controls (-129.72,-49.82) and (-136.20,-50.72) .. (-138.18,-51.08)
 .. controls (-140.16,-51.44) and (-143.40,-54.13) .. (-144.84,-59.53)
 .. controls (-146.28,-64.93) and (-150.24,-75.02) .. (-154.92,-79.52)
 .. controls (-159.60,-84.02) and (-159.96,-90.86) .. (-164.82,-94.46)
 .. controls (-169.69,-98.06) and (-175.63,-101.66) .. (-176.71,-104.90)
 .. controls (-177.79,-108.14) and (-179.95,-118.58) .. (-181.93,-120.92)
 .. controls (-183.91,-123.26) and (-196.15,-131.72) .. (-199.03,-133.52)
 .. controls (-201.91,-135.32) and (-211.09,-147.38) .. (-214.15,-148.10)
 .. controls (-217.22,-148.82) and (-221.90,-147.38) .. (-227.48,-152.96)
 .. controls (-233.06,-158.54) and (-235.94,-161.96) .. (-239.36,-164.30)
 .. controls (-242.78,-166.64) and (-248.90,-170.78) .. (-251.60,-171.50)
 .. controls (-254.30,-172.22) and (-257.72,-176.18) .. (-260.60,-176.18)
 .. controls (-263.48,-176.18) and (-266.00,-177.44) .. (-269.78,-177.44)
),
((213.17,272.39)
 .. controls (213.17,272.39) and (236.57,245.39) .. (241.61,239.62)
 .. controls (246.65,233.86) and (243.77,204.34) .. (245.21,193.90)
),
((-460.06,-315.13)
 .. controls (-459.16,-315.32) and (-450.70,-318.92) .. (-441.70,-319.28)
 .. controls (-432.70,-319.64) and (-429.82,-322.34) .. (-424.24,-324.32)
 .. controls (-418.66,-326.30) and (-415.23,-324.32) .. (-407.13,-322.70)
 .. controls (-399.03,-321.08) and (-394.17,-332.78) .. (-392.19,-336.38)
 .. controls (-390.21,-339.98) and (-370.77,-347.36) .. (-362.13,-351.32)
 .. controls (-353.49,-355.28) and (-336.03,-343.58) .. (-330.09,-338.90)
 .. controls (-324.15,-334.22) and (-315.15,-320.36) .. (-311.19,-315.32)
 .. controls (-307.23,-310.28) and (-295.89,-300.92) .. (-293.19,-295.16)
 .. controls (-290.49,-289.40) and (-291.21,-281.66) .. (-287.07,-271.40)
 .. controls (-282.92,-261.14) and (-277.70,-258.26) .. (-274.64,-253.94)
 .. controls (-271.58,-249.62) and (-258.44,-241.70) .. (-255.20,-237.38)
 .. controls (-251.96,-233.06) and (-253.94,-229.46) .. (-249.08,-220.46)
 .. controls (-244.22,-211.46) and (-237.92,-210.02) .. (-235.94,-207.50)
 .. controls (-233.96,-204.98) and (-226.03,-200.48) .. (-223.15,-198.68)
 .. controls (-220.27,-196.88) and (-214.87,-192.56) .. (-211.81,-189.32)
 .. controls (-208.75,-186.08) and (-199.39,-181.58) .. (-195.43,-178.16)
 .. controls (-191.47,-174.74) and (-188.05,-171.32) .. (-183.91,-168.08)
 .. controls (-179.77,-164.84) and (-173.47,-161.06) .. (-170.59,-158.36)
 .. controls (-167.71,-155.66) and (-164.47,-151.52) .. (-158.89,-142.88)
 .. controls (-153.31,-134.24) and (-146.65,-138.20) .. (-141.25,-138.74)
 .. controls (-135.85,-139.28) and (-126.49,-136.58) .. (-116.04,-133.34)
 .. controls (-105.60,-130.10) and (-101.82,-120.38) .. (-97.50,-114.08)
 .. controls (-93.18,-107.78) and (-89.22,-97.52) .. (-87.60,-94.28)
 .. controls (-85.98,-91.04) and (-81.12,-83.84) .. (-79.14,-81.68)
 .. controls (-77.16,-79.52) and (-69.60,-73.22) .. (-67.98,-69.62)
 .. controls (-66.36,-66.02) and (-66.00,-61.16) .. (-63.30,-58.64)
 .. controls (-60.60,-56.12) and (-52.86,-53.60) .. (-49.62,-52.34)
 .. controls (-46.38,-51.08) and (-41.16,-48.20) .. (-34.86,-44.60)
 .. controls (-28.56,-41.00) and (-27.48,-37.40) .. (-26.76,-34.16)
 .. controls (-26.04,-30.92) and (-19.38,-20.84) .. (-15.42,-14.72)
 .. controls (-11.46,-8.60) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.65,39.29) .. (23.81,40.73)
 .. controls (25.97,42.17) and (29.39,45.77) .. (37.31,47.57)
 .. controls (45.23,49.37) and (61.07,61.43) .. (63.77,65.39)
 .. controls (66.47,69.35) and (91.31,86.09) .. (94.37,88.43)
 .. controls (97.43,90.77) and (111.65,108.77) .. (114.53,112.01)
 .. controls (117.41,115.25) and (120.47,123.71) .. (122.99,125.51)
 .. controls (125.51,127.31) and (126.05,132.35) .. (131.27,133.61)
 .. controls (136.49,134.87) and (140.27,133.25) .. (144.95,133.43)
 .. controls (149.63,133.61) and (157.73,141.35) .. (161.15,145.67)
 .. controls (164.57,149.99) and (180.41,161.33) .. (184.37,164.03)
 .. controls (188.33,166.73) and (204.89,175.73) .. (212.63,180.77)
 .. controls (220.37,185.81) and (240.71,201.46) .. (251.87,211.00)
 .. controls (263.03,220.54) and (269.15,215.32) .. (273.29,214.42)
 .. controls (277.43,213.52) and (283.91,214.60) .. (291.83,216.76)
 .. controls (299.75,218.92) and (310.73,234.04) .. (310.37,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
),
((32.45,106.79)
 .. controls (32.45,106.79) and (56.21,88.79) .. (62.69,96.35)
 .. controls (69.17,103.91) and (87.89,122.27) .. (95.09,116.87)
 .. controls (102.29,111.47) and (118.13,101.75) .. (123.17,105.71)
)));
current_src := "Romeo_entrance.th2 [3802]";
string area_border[];
area_border[1] := "l234-2647-4824";
area_border[2] := "l235-2856-4769";
area_border[3] := "l227-2946-4718";
drawoptions();
a_blocks(buildcycle(((-290.66,-210.92)
 .. controls (-293.36,-211.82) and (-295.34,-212.36) .. (-300.92,-212.90)
 .. controls (-306.50,-213.44) and (-307.76,-214.16) .. (-314.06,-214.70)
 .. controls (-320.36,-215.24) and (-324.50,-214.88) .. (-329.91,-216.32)
 .. controls (-335.31,-217.76) and (-339.09,-217.76) .. (-341.79,-222.08)
 .. controls (-344.49,-226.40) and (-345.21,-230.00) .. (-345.39,-236.48)
 .. controls (-345.57,-242.96) and (-340.71,-246.02) .. (-343.59,-249.98)
 .. controls (-346.47,-253.94) and (-355.11,-251.96) .. (-354.21,-260.42)
 .. controls (-353.31,-268.88) and (-356.01,-276.44) .. (-351.87,-285.98)
 .. controls (-347.73,-295.52) and (-345.03,-295.16) .. (-338.91,-293.72)
 .. controls (-332.79,-292.28) and (-322.89,-298.04) .. (-317.67,-300.56)
 .. controls (-312.45,-303.08) and (-303.81,-308.30) .. (-302.91,-300.20)
 .. controls (-302.01,-292.10) and (-289.77,-296.78) .. (-307.41,-287.24)
 .. controls (-325.05,-277.70) and (-325.95,-278.78) .. (-329.01,-269.06)
 .. controls (-332.07,-259.34) and (-330.45,-251.42) .. (-326.67,-248.00)
 .. controls (-322.89,-244.58) and (-318.03,-242.42) .. (-312.27,-242.96)
 .. controls (-306.51,-243.50) and (-298.40,-243.50) .. (-296.42,-242.06)
 .. controls (-294.44,-240.62) and (-290.12,-240.08) .. (-290.12,-240.08)
),
((-284.36,-218.84)
 .. controls (-284.36,-218.84) and (-290.84,-224.78) .. (-291.02,-229.10)
 .. controls (-291.20,-233.42) and (-292.10,-243.86) .. (-291.20,-246.02)
 .. controls (-290.30,-248.18) and (-286.52,-256.10) .. (-284.90,-257.18)
 .. controls (-283.28,-258.26) and (-277.88,-263.12) .. (-277.88,-263.12)
),
((-266.81,-248.36)
 .. controls (-266.81,-248.36) and (-268.61,-247.82) .. (-269.51,-247.82)
 .. controls (-270.41,-247.82) and (-272.75,-246.38) .. (-274.46,-245.57)
 .. controls (-276.17,-244.76) and (-275.18,-241.34) .. (-274.37,-237.92)
 .. controls (-273.56,-234.50) and (-271.94,-230.72) .. (-271.49,-229.01)
 .. controls (-271.04,-227.30) and (-270.86,-224.60) .. (-271.58,-221.09)
 .. controls (-272.30,-217.58) and (-273.83,-216.05) .. (-273.83,-216.05)
 .. controls (-273.83,-216.05) and (-274.73,-217.04) .. (-275.45,-217.31)
 .. controls (-276.17,-217.58) and (-281.57,-219.47) .. (-284.36,-218.84)
 .. controls (-287.15,-218.21) and (-290.57,-214.97) .. (-292.19,-212.81)
 .. controls (-293.81,-210.65) and (-294.44,-203.27) .. (-294.80,-199.67)
 .. controls (-295.16,-196.07) and (-291.74,-187.52) .. (-290.03,-184.64)
 .. controls (-288.32,-181.76) and (-285.71,-182.48) .. (-283.82,-180.95)
 .. controls (-281.93,-179.42) and (-278.06,-179.15) .. (-276.35,-178.79)
 .. controls (-274.64,-178.43) and (-269.78,-177.44) .. (-269.78,-177.44)
)));
current_src := "Romeo_entrance.th2 [3795]";
string area_border[];
area_border[1] := "l238-2596-4325";
area_border[2] := "l87-5698-7070";
area_border[3] := "l235-2856-4769";
area_border[4] := "l234-2647-4824";
drawoptions();
a_pebbles(buildcycle(((-341.61,-293.54)
 .. controls (-340.53,-294.44) and (-333.87,-311.72) .. (-331.71,-315.86)
 .. controls (-329.55,-320.00) and (-317.67,-325.76) .. (-317.67,-325.76)
),
((-460.06,-315.13)
 .. controls (-459.16,-315.32) and (-450.70,-318.92) .. (-441.70,-319.28)
 .. controls (-432.70,-319.64) and (-429.82,-322.34) .. (-424.24,-324.32)
 .. controls (-418.66,-326.30) and (-415.23,-324.32) .. (-407.13,-322.70)
 .. controls (-399.03,-321.08) and (-394.17,-332.78) .. (-392.19,-336.38)
 .. controls (-390.21,-339.98) and (-370.77,-347.36) .. (-362.13,-351.32)
 .. controls (-353.49,-355.28) and (-336.03,-343.58) .. (-330.09,-338.90)
 .. controls (-324.15,-334.22) and (-315.15,-320.36) .. (-311.19,-315.32)
 .. controls (-307.23,-310.28) and (-295.89,-300.92) .. (-293.19,-295.16)
 .. controls (-290.49,-289.40) and (-291.21,-281.66) .. (-287.07,-271.40)
 .. controls (-282.92,-261.14) and (-277.70,-258.26) .. (-274.64,-253.94)
 .. controls (-271.58,-249.62) and (-258.44,-241.70) .. (-255.20,-237.38)
 .. controls (-251.96,-233.06) and (-253.94,-229.46) .. (-249.08,-220.46)
 .. controls (-244.22,-211.46) and (-237.92,-210.02) .. (-235.94,-207.50)
 .. controls (-233.96,-204.98) and (-226.03,-200.48) .. (-223.15,-198.68)
 .. controls (-220.27,-196.88) and (-214.87,-192.56) .. (-211.81,-189.32)
 .. controls (-208.75,-186.08) and (-199.39,-181.58) .. (-195.43,-178.16)
 .. controls (-191.47,-174.74) and (-188.05,-171.32) .. (-183.91,-168.08)
 .. controls (-179.77,-164.84) and (-173.47,-161.06) .. (-170.59,-158.36)
 .. controls (-167.71,-155.66) and (-164.47,-151.52) .. (-158.89,-142.88)
 .. controls (-153.31,-134.24) and (-146.65,-138.20) .. (-141.25,-138.74)
 .. controls (-135.85,-139.28) and (-126.49,-136.58) .. (-116.04,-133.34)
 .. controls (-105.60,-130.10) and (-101.82,-120.38) .. (-97.50,-114.08)
 .. controls (-93.18,-107.78) and (-89.22,-97.52) .. (-87.60,-94.28)
 .. controls (-85.98,-91.04) and (-81.12,-83.84) .. (-79.14,-81.68)
 .. controls (-77.16,-79.52) and (-69.60,-73.22) .. (-67.98,-69.62)
 .. controls (-66.36,-66.02) and (-66.00,-61.16) .. (-63.30,-58.64)
 .. controls (-60.60,-56.12) and (-52.86,-53.60) .. (-49.62,-52.34)
 .. controls (-46.38,-51.08) and (-41.16,-48.20) .. (-34.86,-44.60)
 .. controls (-28.56,-41.00) and (-27.48,-37.40) .. (-26.76,-34.16)
 .. controls (-26.04,-30.92) and (-19.38,-20.84) .. (-15.42,-14.72)
 .. controls (-11.46,-8.60) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.65,39.29) .. (23.81,40.73)
 .. controls (25.97,42.17) and (29.39,45.77) .. (37.31,47.57)
 .. controls (45.23,49.37) and (61.07,61.43) .. (63.77,65.39)
 .. controls (66.47,69.35) and (91.31,86.09) .. (94.37,88.43)
 .. controls (97.43,90.77) and (111.65,108.77) .. (114.53,112.01)
 .. controls (117.41,115.25) and (120.47,123.71) .. (122.99,125.51)
 .. controls (125.51,127.31) and (126.05,132.35) .. (131.27,133.61)
 .. controls (136.49,134.87) and (140.27,133.25) .. (144.95,133.43)
 .. controls (149.63,133.61) and (157.73,141.35) .. (161.15,145.67)
 .. controls (164.57,149.99) and (180.41,161.33) .. (184.37,164.03)
 .. controls (188.33,166.73) and (204.89,175.73) .. (212.63,180.77)
 .. controls (220.37,185.81) and (240.71,201.46) .. (251.87,211.00)
 .. controls (263.03,220.54) and (269.15,215.32) .. (273.29,214.42)
 .. controls (277.43,213.52) and (283.91,214.60) .. (291.83,216.76)
 .. controls (299.75,218.92) and (310.73,234.04) .. (310.37,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
),
((-284.36,-218.84)
 .. controls (-284.36,-218.84) and (-290.84,-224.78) .. (-291.02,-229.10)
 .. controls (-291.20,-233.42) and (-292.10,-243.86) .. (-291.20,-246.02)
 .. controls (-290.30,-248.18) and (-286.52,-256.10) .. (-284.90,-257.18)
 .. controls (-283.28,-258.26) and (-277.88,-263.12) .. (-277.88,-263.12)
),
((-290.66,-210.92)
 .. controls (-293.36,-211.82) and (-295.34,-212.36) .. (-300.92,-212.90)
 .. controls (-306.50,-213.44) and (-307.76,-214.16) .. (-314.06,-214.70)
 .. controls (-320.36,-215.24) and (-324.50,-214.88) .. (-329.91,-216.32)
 .. controls (-335.31,-217.76) and (-339.09,-217.76) .. (-341.79,-222.08)
 .. controls (-344.49,-226.40) and (-345.21,-230.00) .. (-345.39,-236.48)
 .. controls (-345.57,-242.96) and (-340.71,-246.02) .. (-343.59,-249.98)
 .. controls (-346.47,-253.94) and (-355.11,-251.96) .. (-354.21,-260.42)
 .. controls (-353.31,-268.88) and (-356.01,-276.44) .. (-351.87,-285.98)
 .. controls (-347.73,-295.52) and (-345.03,-295.16) .. (-338.91,-293.72)
 .. controls (-332.79,-292.28) and (-322.89,-298.04) .. (-317.67,-300.56)
 .. controls (-312.45,-303.08) and (-303.81,-308.30) .. (-302.91,-300.20)
 .. controls (-302.01,-292.10) and (-289.77,-296.78) .. (-307.41,-287.24)
 .. controls (-325.05,-277.70) and (-325.95,-278.78) .. (-329.01,-269.06)
 .. controls (-332.07,-259.34) and (-330.45,-251.42) .. (-326.67,-248.00)
 .. controls (-322.89,-244.58) and (-318.03,-242.42) .. (-312.27,-242.96)
 .. controls (-306.51,-243.50) and (-298.40,-243.50) .. (-296.42,-242.06)
 .. controls (-294.44,-240.62) and (-290.12,-240.08) .. (-290.12,-240.08)
)));
current_src := "Romeo_entrance.th2 [3788]";
string area_border[];
area_border[1] := "l235-2856-4769";
area_border[2] := "l87-5698-7070";
area_border[3] := "l227-2946-4718";
area_border[4] := "l235-2856-4769";
drawoptions();
a_water(buildcycle(((-284.36,-218.84)
 .. controls (-284.36,-218.84) and (-290.84,-224.78) .. (-291.02,-229.10)
 .. controls (-291.20,-233.42) and (-292.10,-243.86) .. (-291.20,-246.02)
 .. controls (-290.30,-248.18) and (-286.52,-256.10) .. (-284.90,-257.18)
 .. controls (-283.28,-258.26) and (-277.88,-263.12) .. (-277.88,-263.12)
),
((-460.06,-315.13)
 .. controls (-459.16,-315.32) and (-450.70,-318.92) .. (-441.70,-319.28)
 .. controls (-432.70,-319.64) and (-429.82,-322.34) .. (-424.24,-324.32)
 .. controls (-418.66,-326.30) and (-415.23,-324.32) .. (-407.13,-322.70)
 .. controls (-399.03,-321.08) and (-394.17,-332.78) .. (-392.19,-336.38)
 .. controls (-390.21,-339.98) and (-370.77,-347.36) .. (-362.13,-351.32)
 .. controls (-353.49,-355.28) and (-336.03,-343.58) .. (-330.09,-338.90)
 .. controls (-324.15,-334.22) and (-315.15,-320.36) .. (-311.19,-315.32)
 .. controls (-307.23,-310.28) and (-295.89,-300.92) .. (-293.19,-295.16)
 .. controls (-290.49,-289.40) and (-291.21,-281.66) .. (-287.07,-271.40)
 .. controls (-282.92,-261.14) and (-277.70,-258.26) .. (-274.64,-253.94)
 .. controls (-271.58,-249.62) and (-258.44,-241.70) .. (-255.20,-237.38)
 .. controls (-251.96,-233.06) and (-253.94,-229.46) .. (-249.08,-220.46)
 .. controls (-244.22,-211.46) and (-237.92,-210.02) .. (-235.94,-207.50)
 .. controls (-233.96,-204.98) and (-226.03,-200.48) .. (-223.15,-198.68)
 .. controls (-220.27,-196.88) and (-214.87,-192.56) .. (-211.81,-189.32)
 .. controls (-208.75,-186.08) and (-199.39,-181.58) .. (-195.43,-178.16)
 .. controls (-191.47,-174.74) and (-188.05,-171.32) .. (-183.91,-168.08)
 .. controls (-179.77,-164.84) and (-173.47,-161.06) .. (-170.59,-158.36)
 .. controls (-167.71,-155.66) and (-164.47,-151.52) .. (-158.89,-142.88)
 .. controls (-153.31,-134.24) and (-146.65,-138.20) .. (-141.25,-138.74)
 .. controls (-135.85,-139.28) and (-126.49,-136.58) .. (-116.04,-133.34)
 .. controls (-105.60,-130.10) and (-101.82,-120.38) .. (-97.50,-114.08)
 .. controls (-93.18,-107.78) and (-89.22,-97.52) .. (-87.60,-94.28)
 .. controls (-85.98,-91.04) and (-81.12,-83.84) .. (-79.14,-81.68)
 .. controls (-77.16,-79.52) and (-69.60,-73.22) .. (-67.98,-69.62)
 .. controls (-66.36,-66.02) and (-66.00,-61.16) .. (-63.30,-58.64)
 .. controls (-60.60,-56.12) and (-52.86,-53.60) .. (-49.62,-52.34)
 .. controls (-46.38,-51.08) and (-41.16,-48.20) .. (-34.86,-44.60)
 .. controls (-28.56,-41.00) and (-27.48,-37.40) .. (-26.76,-34.16)
 .. controls (-26.04,-30.92) and (-19.38,-20.84) .. (-15.42,-14.72)
 .. controls (-11.46,-8.60) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.65,39.29) .. (23.81,40.73)
 .. controls (25.97,42.17) and (29.39,45.77) .. (37.31,47.57)
 .. controls (45.23,49.37) and (61.07,61.43) .. (63.77,65.39)
 .. controls (66.47,69.35) and (91.31,86.09) .. (94.37,88.43)
 .. controls (97.43,90.77) and (111.65,108.77) .. (114.53,112.01)
 .. controls (117.41,115.25) and (120.47,123.71) .. (122.99,125.51)
 .. controls (125.51,127.31) and (126.05,132.35) .. (131.27,133.61)
 .. controls (136.49,134.87) and (140.27,133.25) .. (144.95,133.43)
 .. controls (149.63,133.61) and (157.73,141.35) .. (161.15,145.67)
 .. controls (164.57,149.99) and (180.41,161.33) .. (184.37,164.03)
 .. controls (188.33,166.73) and (204.89,175.73) .. (212.63,180.77)
 .. controls (220.37,185.81) and (240.71,201.46) .. (251.87,211.00)
 .. controls (263.03,220.54) and (269.15,215.32) .. (273.29,214.42)
 .. controls (277.43,213.52) and (283.91,214.60) .. (291.83,216.76)
 .. controls (299.75,218.92) and (310.73,234.04) .. (310.37,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
),
((-266.81,-248.36)
 .. controls (-266.81,-248.36) and (-268.61,-247.82) .. (-269.51,-247.82)
 .. controls (-270.41,-247.82) and (-272.75,-246.38) .. (-274.46,-245.57)
 .. controls (-276.17,-244.76) and (-275.18,-241.34) .. (-274.37,-237.92)
 .. controls (-273.56,-234.50) and (-271.94,-230.72) .. (-271.49,-229.01)
 .. controls (-271.04,-227.30) and (-270.86,-224.60) .. (-271.58,-221.09)
 .. controls (-272.30,-217.58) and (-273.83,-216.05) .. (-273.83,-216.05)
 .. controls (-273.83,-216.05) and (-274.73,-217.04) .. (-275.45,-217.31)
 .. controls (-276.17,-217.58) and (-281.57,-219.47) .. (-284.36,-218.84)
 .. controls (-287.15,-218.21) and (-290.57,-214.97) .. (-292.19,-212.81)
 .. controls (-293.81,-210.65) and (-294.44,-203.27) .. (-294.80,-199.67)
 .. controls (-295.16,-196.07) and (-291.74,-187.52) .. (-290.03,-184.64)
 .. controls (-288.32,-181.76) and (-285.71,-182.48) .. (-283.82,-180.95)
 .. controls (-281.93,-179.42) and (-278.06,-179.15) .. (-276.35,-178.79)
 .. controls (-274.64,-178.43) and (-269.78,-177.44) .. (-269.78,-177.44)
),
((-284.36,-218.84)
 .. controls (-284.36,-218.84) and (-290.84,-224.78) .. (-291.02,-229.10)
 .. controls (-291.20,-233.42) and (-292.10,-243.86) .. (-291.20,-246.02)
 .. controls (-290.30,-248.18) and (-286.52,-256.10) .. (-284.90,-257.18)
 .. controls (-283.28,-258.26) and (-277.88,-263.12) .. (-277.88,-263.12)
)));
current_src := "Romeo_entrance.th2 [3784]";
string area_border[];
area_border[1] := "l215-6016-7619";
drawoptions();
a_water(buildcycle(((279.96,285.16)
 .. controls (277.62,288.40) and (276.90,290.56) .. (274.92,293.26)
 .. controls (272.94,295.96) and (269.70,297.40) .. (267.72,298.84)
 .. controls (265.74,300.28) and (261.60,302.27) .. (257.46,302.81)
 .. controls (253.32,303.35) and (253.14,301.37) .. (248.82,298.31)
 .. controls (244.50,295.25) and (238.74,291.65) .. (235.49,287.51)
 .. controls (232.25,283.37) and (230.63,278.33) .. (229.01,272.57)
 .. controls (227.39,266.81) and (232.97,253.85) .. (233.69,252.95)
 .. controls (234.41,252.05) and (235.49,248.27) .. (235.13,244.67)
 .. controls (234.77,241.07) and (231.17,236.03) .. (229.73,231.71)
 .. controls (228.29,227.39) and (226.85,227.03) .. (223.25,224.87)
 .. controls (219.65,222.71) and (213.35,226.31) .. (211.55,226.85)
 .. controls (209.75,227.39) and (206.69,229.91) .. (203.27,229.37)
 .. controls (199.85,228.83) and (192.83,225.41) .. (188.15,221.63)
 .. controls (183.47,217.85) and (186.35,215.51) .. (185.99,208.67)
 .. controls (185.63,201.83) and (184.73,199.31) .. (181.67,194.99)
 .. controls (178.61,190.67) and (172.49,190.31) .. (169.25,190.85)
 .. controls (166.01,191.39) and (158.63,190.13) .. (153.77,188.15)
 .. controls (148.91,186.17) and (141.71,184.01) .. (137.75,179.69)
 .. controls (133.79,175.37) and (132.89,170.87) .. (129.83,164.75)
 .. controls (126.77,158.63) and (122.27,160.25) .. (118.31,159.71)
 .. controls (114.35,159.17) and (107.15,155.21) .. (104.27,153.23)
 .. controls (101.39,151.25) and (95.27,146.75) .. (93.47,145.49)
 .. controls (91.67,144.23) and (85.37,137.57) .. (81.23,132.89)
 .. controls (77.09,128.21) and (69.89,119.21) .. (66.65,117.05)
 .. controls (63.41,114.89) and (53.15,102.29) .. (50.45,98.15)
 .. controls (47.75,94.01) and (31.01,85.55) .. (25.79,82.67)
 .. controls (20.57,79.79) and (15.35,76.55) .. (12.83,74.03)
 .. controls (10.31,71.51) and (8.51,63.59) .. (7.07,59.63)
 .. controls (5.63,55.67) and (1.67,55.85) .. (-2.65,52.97)
 .. controls (-6.97,50.09) and (-8.41,52.07) .. (-10.03,49.73)
 .. controls (-11.65,47.39) and (-28.20,32.44) .. (-30.36,29.92)
 .. controls (-32.52,27.40) and (-37.56,21.82) .. (-39.54,18.22)
 .. controls (-41.52,14.62) and (-47.46,7.78) .. (-49.08,5.44)
 .. controls (-50.70,3.10) and (-55.56,-3.02) .. (-57.00,-5.00)
 .. controls (-58.44,-6.98) and (-65.10,-14.54) .. (-66.54,-15.98)
 .. controls (-67.98,-17.42) and (-71.94,-21.74) .. (-74.82,-26.96)
 .. controls (-77.70,-32.18) and (-78.24,-31.46) .. (-78.60,-35.96)
 .. controls (-78.96,-40.46) and (-77.70,-41.72) .. (-74.46,-44.60)
 .. controls (-71.22,-47.48) and (-70.68,-47.84) .. (-67.26,-47.84)
 .. controls (-63.84,-47.84) and (-63.30,-46.76) .. (-61.86,-46.04)
 .. controls (-60.42,-45.32) and (-58.98,-43.34) .. (-57.36,-40.82)
 .. controls (-55.74,-38.30) and (-53.76,-38.66) .. (-50.16,-33.80)
 .. controls (-46.56,-28.94) and (-44.40,-28.40) .. (-42.24,-25.88)
 .. controls (-40.08,-23.36) and (-40.80,-21.02) .. (-39.00,-17.42)
 .. controls (-37.20,-13.82) and (-36.84,-12.74) .. (-35.76,-9.50)
 .. controls (-34.68,-6.26) and (-35.94,-3.56) .. (-34.86,0.04)
 .. controls (-33.78,3.64) and (-32.16,7.24) .. (-29.28,11.38)
 .. controls (-26.40,15.52) and (-21.72,20.02) .. (-17.76,23.44)
 .. controls (-13.80,26.86) and (-9.48,26.32) .. (-8.04,27.05)
 .. controls (-6.60,27.77) and (-3.00,32.99) .. (-1.56,35.69)
 .. controls (-0.12,38.39) and (0.42,38.03) .. (2.94,41.09)
 .. controls (5.45,44.15) and (9.77,46.49) .. (12.11,47.39)
 .. controls (14.45,48.29) and (17.15,50.09) .. (20.03,52.25)
 .. controls (22.91,54.41) and (22.91,55.13) .. (25.25,56.93)
 .. controls (27.59,58.73) and (35.15,65.21) .. (37.85,68.27)
 .. controls (40.55,71.33) and (49.55,77.99) .. (51.53,79.61)
 .. controls (53.51,81.23) and (74.21,95.09) .. (76.01,98.15)
 .. controls (77.81,101.21) and (92.57,111.11) .. (97.07,113.45)
 .. controls (101.57,115.79) and (108.59,122.81) .. (111.29,125.33)
 .. controls (113.99,127.85) and (117.23,132.35) .. (117.77,135.23)
 .. controls (118.31,138.11) and (120.83,136.85) .. (125.15,137.21)
 .. controls (129.47,137.57) and (133.43,139.73) .. (135.23,140.09)
 .. controls (137.03,140.45) and (140.63,144.23) .. (144.59,146.93)
 .. controls (148.55,149.63) and (151.97,150.71) .. (155.21,154.13)
 .. controls (158.45,157.55) and (161.15,160.25) .. (162.41,164.93)
 .. controls (163.67,169.61) and (162.05,170.51) .. (163.31,173.39)
 .. controls (164.57,176.27) and (166.37,177.17) .. (169.07,177.35)
 .. controls (171.77,177.53) and (174.83,177.89) .. (178.97,179.51)
 .. controls (183.11,181.13) and (184.55,182.39) .. (188.69,184.73)
 .. controls (192.83,187.07) and (196.43,189.59) .. (200.39,192.29)
 .. controls (204.35,194.99) and (207.41,195.89) .. (209.39,198.41)
 .. controls (211.37,200.93) and (210.47,201.29) .. (211.37,206.15)
 .. controls (212.27,211.01) and (216.59,209.93) .. (220.73,211.19)
 .. controls (224.87,212.45) and (225.59,212.63) .. (228.83,213.53)
 .. controls (232.07,214.42) and (237.47,216.94) .. (240.53,217.48)
 .. controls (243.59,218.02) and (246.29,223.06) .. (250.97,225.04)
 .. controls (255.65,227.02) and (256.01,225.76) .. (260.15,225.04)
 .. controls (264.29,224.32) and (268.79,223.78) .. (273.29,221.98)
 .. controls (277.79,220.18) and (282.11,221.44) .. (284.81,222.34)
 .. controls (287.51,223.24) and (293.45,228.82) .. (295.07,231.70)
 .. controls (296.69,234.58) and (304.07,244.12) .. (306.78,250.42)
 .. controls (309.48,256.72) and (305.88,260.50) .. (303.54,264.28)
 .. controls (301.20,268.06) and (298.14,270.40) .. (295.62,272.38)
 .. controls (293.10,274.36) and (288.78,277.60) .. (285.00,278.50)
 .. controls (281.22,279.40) and (282.30,281.92) .. cycle
)));
current_src := "Romeo_entrance.th2 [3598]";
string area_border[];
area_border[1] := "l676-3922-5910";
drawoptions();
a_debris(buildcycle(((-115.14,-28.22)
 -- (-75.54,-93.38)
 -- (-53.22,-69.98)
 -- (-96.06,-20.66)
 -- cycle
)));
ATTR__height := -1;
drawoptions();
l_pit(((-254.65,232.24)
 .. controls (-254.65,232.24) and (-256.45,232.42) .. (-251.59,228.82)
 .. controls (-246.73,225.22) and (-241.15,211.90) .. (-241.33,201.64)
 .. controls (-241.51,191.38) and (-244.75,167.08) .. (-242.41,165.64)
 .. controls (-240.07,164.20) and (-240.61,163.30) .. (-233.59,161.14)
 .. controls (-226.57,158.98) and (-220.99,158.80) .. (-216.85,158.26)
 .. controls (-212.71,157.72) and (-200.65,157.72) .. (-198.67,157.90)
 .. controls (-196.69,158.08) and (-173.83,158.62) .. (-170.95,157.72)
 .. controls (-168.07,156.82) and (-166.63,156.28) .. (-163.03,155.38)
 .. controls (-159.43,154.48) and (-152.59,152.86) .. (-147.19,153.94)
 .. controls (-141.79,155.02) and (-137.65,156.46) .. (-137.65,156.46)
));
ATTR__height := -1;
drawoptions();
l_pit(((-291.92,-15.44)
 .. controls (-290.48,-18.14) and (-285.80,-21.92) .. (-283.46,-23.36)
 .. controls (-281.12,-24.80) and (-276.80,-26.78) .. (-274.46,-26.60)
 .. controls (-272.12,-26.43) and (-270.86,-27.33) .. (-265.46,-24.27)
 .. controls (-260.06,-21.21) and (-257.90,-21.93) .. (-256.46,-18.33)
 .. controls (-255.02,-14.73) and (-249.08,-9.69) .. (-246.02,-9.69)
 .. controls (-242.96,-9.69) and (-242.78,-12.03) .. (-240.62,-15.45)
 .. controls (-238.46,-18.87) and (-238.64,-17.43) .. (-236.66,-21.21)
 .. controls (-234.68,-24.99) and (-230.02,-25.89) .. (-226.59,-25.89)
 .. controls (-222.45,-25.89) and (-219.39,-23.73) .. (-215.43,-21.75)
 .. controls (-211.47,-19.77) and (-208.59,-18.69) .. (-206.06,-17.42)
 .. controls (-203.54,-16.16) and (-197.96,-14.54) .. (-197.96,-14.54)
));
ATTR__id := "l2-3472-6720";
ATTR__height := -1;
drawoptions();
l_pit(((-196.15,142.60)
 .. controls (-198.13,143.32) and (-199.75,142.60) .. (-202.99,143.14)
 .. controls (-206.23,143.68) and (-212.17,143.68) .. (-217.21,143.86)
 .. controls (-222.25,144.04) and (-226.03,142.42) .. (-233.23,140.26)
 .. controls (-240.43,138.10) and (-237.73,135.22) .. (-244.57,125.50)
 .. controls (-251.41,115.78) and (-242.41,101.92) .. (-247.99,89.32)
 .. controls (-253.57,76.72) and (-248.35,76.00) .. (-251.05,63.58)
 .. controls (-253.76,51.16) and (-252.32,44.68) .. (-251.42,31.35)
 .. controls (-250.52,18.03) and (-249.62,17.13) .. (-249.62,5.43)
 .. controls (-249.62,-6.27) and (-249.62,1.83) .. (-247.64,-4.65)
 .. controls (-245.66,-11.13) and (-244.40,-6.63) .. (-241.16,-7.53)
 .. controls (-237.92,-8.43) and (-233.96,-8.97) .. (-231.80,-8.61)
 .. controls (-229.64,-8.25) and (-224.24,-5.73) .. (-219.02,-4.11)
 .. controls (-213.80,-2.49) and (-213.80,0.57) .. (-210.02,7.06)
 .. controls (-206.24,13.54) and (-205.88,23.98) .. (-201.20,30.28)
 .. controls (-196.51,36.58) and (-194.35,47.02) .. (-192.01,52.42)
 .. controls (-189.67,57.82) and (-184.45,62.68) .. (-179.77,68.98)
 .. controls (-175.09,75.28) and (-173.47,83.20) .. (-171.49,89.14)
 .. controls (-169.51,95.08) and (-168.25,96.52) .. (-171.13,99.22)
 .. controls (-174.01,101.92) and (-176.71,97.60) .. (-181.21,99.22)
 .. controls (-185.71,100.84) and (-180.85,101.56) .. (-181.39,112.36)
 .. controls (-181.93,123.16) and (-177.79,126.76) .. (-179.23,133.78)
 .. controls (-180.67,140.80) and (-194.17,141.88) .. cycle
));
ATTR__id := "l238-2596-4325";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-341.61,-293.54)
 .. controls (-340.53,-294.44) and (-333.87,-311.72) .. (-331.71,-315.86)
 .. controls (-329.55,-320.00) and (-317.67,-325.76) .. (-317.67,-325.76)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-302.00,-154.94)
 .. controls (-302.00,-154.94) and (-264.56,-148.10) .. (-282.56,-89.79)
));
ATTR__height := -1;
drawoptions();
l_floorstep(((-318.38,-190.22)
 .. controls (-318.38,-190.22) and (-298.76,-186.26) .. (-294.44,-152.06)
));
ATTR__height := -1;
drawoptions();
l_pit(((-391.29,-290.66)
 .. controls (-372.21,-307.94) and (-389.85,-292.82) .. (-375.45,-305.06)
 .. controls (-361.05,-317.30) and (-371.13,-347.54) .. (-371.13,-347.54)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-421.53,-286.70)
 .. controls (-421.53,-286.70) and (-391.29,-287.78) .. (-395.61,-252.14)
));
ATTR__height := -1;
drawoptions();
l_pit(((-368.97,-213.62)
 .. controls (-368.97,-213.62) and (-371.85,-230.18) .. (-377.61,-232.34)
 .. controls (-383.37,-234.50) and (-377.97,-248.18) .. (-372.57,-251.42)
 .. controls (-367.17,-254.66) and (-366.45,-289.94) .. (-391.29,-290.66)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-399.75,-280.76)
 .. controls (-397.77,-282.74) and (-399.03,-282.56) .. (-398.13,-287.96)
 .. controls (-397.23,-293.36) and (-393.27,-289.22) .. (-394.71,-296.78)
 .. controls (-396.15,-304.34) and (-395.61,-303.26) .. (-396.33,-306.14)
));
ATTR__id := "l235-2856-4769";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-284.36,-218.84)
 .. controls (-284.36,-218.84) and (-290.84,-224.78) .. (-291.02,-229.10)
 .. controls (-291.20,-233.42) and (-292.10,-243.86) .. (-291.20,-246.02)
 .. controls (-290.30,-248.18) and (-286.52,-256.10) .. (-284.90,-257.18)
 .. controls (-283.28,-258.26) and (-277.88,-263.12) .. (-277.88,-263.12)
));
ATTR__id := "l234-2647-4824";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-290.66,-210.92)
 .. controls (-293.36,-211.82) and (-295.34,-212.36) .. (-300.92,-212.90)
 .. controls (-306.50,-213.44) and (-307.76,-214.16) .. (-314.06,-214.70)
 .. controls (-320.36,-215.24) and (-324.50,-214.88) .. (-329.91,-216.32)
 .. controls (-335.31,-217.76) and (-339.09,-217.76) .. (-341.79,-222.08)
 .. controls (-344.49,-226.40) and (-345.21,-230.00) .. (-345.39,-236.48)
 .. controls (-345.57,-242.96) and (-340.71,-246.02) .. (-343.59,-249.98)
 .. controls (-346.47,-253.94) and (-355.11,-251.96) .. (-354.21,-260.42)
 .. controls (-353.31,-268.88) and (-356.01,-276.44) .. (-351.87,-285.98)
 .. controls (-347.73,-295.52) and (-345.03,-295.16) .. (-338.91,-293.72)
 .. controls (-332.79,-292.28) and (-322.89,-298.04) .. (-317.67,-300.56)
 .. controls (-312.45,-303.08) and (-303.81,-308.30) .. (-302.91,-300.20)
 .. controls (-302.01,-292.10) and (-289.77,-296.78) .. (-307.41,-287.24)
 .. controls (-325.05,-277.70) and (-325.95,-278.78) .. (-329.01,-269.06)
 .. controls (-332.07,-259.34) and (-330.45,-251.42) .. (-326.67,-248.00)
 .. controls (-322.89,-244.58) and (-318.03,-242.42) .. (-312.27,-242.96)
 .. controls (-306.51,-243.50) and (-298.40,-243.50) .. (-296.42,-242.06)
 .. controls (-294.44,-240.62) and (-290.12,-240.08) .. (-290.12,-240.08)
));
ATTR__id := "l227-2946-4718";
ATTR__height := -1;
drawoptions();
l_pit(((-266.81,-248.36)
 .. controls (-266.81,-248.36) and (-268.61,-247.82) .. (-269.51,-247.82)
 .. controls (-270.41,-247.82) and (-272.75,-246.38) .. (-274.46,-245.57)
 .. controls (-276.17,-244.76) and (-275.18,-241.34) .. (-274.37,-237.92)
 .. controls (-273.56,-234.50) and (-271.94,-230.72) .. (-271.49,-229.01)
 .. controls (-271.04,-227.30) and (-270.86,-224.60) .. (-271.58,-221.09)
 .. controls (-272.30,-217.58) and (-273.83,-216.05) .. (-273.83,-216.05)
 .. controls (-273.83,-216.05) and (-274.73,-217.04) .. (-275.45,-217.31)
 .. controls (-276.17,-217.58) and (-281.57,-219.47) .. (-284.36,-218.84)
 .. controls (-287.15,-218.21) and (-290.57,-214.97) .. (-292.19,-212.81)
 .. controls (-293.81,-210.65) and (-294.44,-203.27) .. (-294.80,-199.67)
 .. controls (-295.16,-196.07) and (-291.74,-187.52) .. (-290.03,-184.64)
 .. controls (-288.32,-181.76) and (-285.71,-182.48) .. (-283.82,-180.95)
 .. controls (-281.93,-179.42) and (-278.06,-179.15) .. (-276.35,-178.79)
 .. controls (-274.64,-178.43) and (-269.78,-177.44) .. (-269.78,-177.44)
));
ATTR__id := "l623-3834-5584";
ATTR__height := -1;
drawoptions();
l_flowstone(((-130.71,-47.57)
 .. controls (-130.71,-47.57) and (-133.50,-49.28) .. (-134.31,-53.15)
 .. controls (-135.12,-57.02) and (-134.94,-60.62) .. (-133.77,-61.61)
 .. controls (-132.60,-62.60) and (-130.08,-64.94) .. (-128.19,-64.85)
 .. controls (-126.30,-64.76) and (-124.59,-65.57) .. (-122.88,-64.94)
 .. controls (-121.17,-64.31) and (-120.00,-64.22) .. (-120.00,-64.22)
 .. controls (-120.00,-64.22) and (-119.82,-70.70) .. (-119.46,-72.50)
 .. controls (-119.10,-74.30) and (-117.21,-78.62) .. (-115.77,-78.89)
 .. controls (-114.33,-79.16) and (-111.99,-79.25) .. (-110.91,-78.80)
 .. controls (-109.83,-78.35) and (-108.39,-77.45) .. (-108.39,-77.45)
 .. controls (-108.39,-77.45) and (-109.11,-80.24) .. (-108.66,-82.31)
 .. controls (-108.21,-84.38) and (-107.31,-91.22) .. (-106.86,-91.94)
 .. controls (-106.41,-92.66) and (-105.69,-95.27) .. (-103.17,-94.82)
 .. controls (-100.65,-94.37) and (-98.22,-94.19) .. (-97.41,-93.92)
 .. controls (-96.60,-93.65) and (-97.95,-99.86) .. (-96.87,-102.38)
 .. controls (-95.79,-104.90) and (-95.43,-105.08) .. (-94.17,-104.99)
 .. controls (-92.91,-104.90) and (-93.63,-107.96) .. (-93.45,-108.95)
));
ATTR__id := "l622-3482-5272";
ATTR__height := -1;
drawoptions();
l_flowstone(((-185.08,-121.28)
 .. controls (-185.08,-121.28) and (-184.36,-129.20) .. (-181.84,-132.44)
 .. controls (-179.32,-135.68) and (-173.92,-138.92) .. (-171.31,-138.20)
 .. controls (-168.70,-137.48) and (-163.66,-135.59) .. (-162.76,-135.59)
));
ATTR__id := "l621-3504-5172";
ATTR__height := -1;
drawoptions();
l_flowstone(((-175.54,-137.66)
 .. controls (-175.54,-137.66) and (-176.98,-141.80) .. (-176.71,-145.22)
 .. controls (-176.44,-148.64) and (-176.89,-152.15) .. (-175.00,-153.86)
 .. controls (-173.11,-155.57) and (-170.14,-158.27) .. (-169.15,-158.18)
));
ATTR__id := "l676-3922-5910";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-115.14,-28.22)
 -- (-75.54,-93.38)
 -- (-53.22,-69.98)
 -- (-96.06,-20.66)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-199.93,-132.53)
 .. controls (-199.93,-132.53) and (-198.04,-136.13) .. (-197.68,-139.19)
 .. controls (-197.32,-142.25) and (-197.68,-148.64) .. (-194.62,-149.90)
 .. controls (-191.56,-151.16) and (-184.63,-151.34) .. (-182.92,-150.89)
 .. controls (-181.21,-150.44) and (-176.62,-149.36) .. (-176.62,-149.36)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-195.70,-149.09)
 .. controls (-195.70,-149.09) and (-200.38,-159.26) .. (-199.84,-162.59)
 .. controls (-199.30,-165.92) and (-198.40,-168.89) .. (-196.33,-170.24)
 .. controls (-194.26,-171.59) and (-188.32,-173.30) .. (-188.32,-173.30)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((-214.87,-146.21)
 .. controls (-214.87,-146.21) and (-214.69,-152.33) .. (-214.15,-154.76)
 .. controls (-213.61,-157.19) and (-212.98,-159.98) .. (-212.35,-163.85)
 .. controls (-211.72,-167.72) and (-210.01,-170.06) .. (-208.66,-170.78)
 .. controls (-207.31,-171.50) and (-205.60,-170.60) .. (-203.35,-170.24)
 .. controls (-201.10,-169.88) and (-197.59,-168.62) .. (-197.59,-168.62)
));
ATTR__id := "l217-5828-7294";
ATTR__height := -1;
drawoptions();
l_border_invisible(((213.17,272.39)
 .. controls (213.17,272.39) and (236.57,245.39) .. (241.61,239.62)
 .. controls (246.65,233.86) and (243.77,204.34) .. (245.21,193.90)
));
ATTR__id := "l218-5044-6636";
ATTR__height := -1;
drawoptions();
l_border_invisible(((32.45,106.79)
 .. controls (32.45,106.79) and (56.21,88.79) .. (62.69,96.35)
 .. controls (69.17,103.91) and (87.89,122.27) .. (95.09,116.87)
 .. controls (102.29,111.47) and (118.13,101.75) .. (123.17,105.71)
));
ATTR__id := "l215-6016-7619";
ATTR__height := -1;
drawoptions();
l_border_invisible(((279.96,285.16)
 .. controls (277.62,288.40) and (276.90,290.56) .. (274.92,293.26)
 .. controls (272.94,295.96) and (269.70,297.40) .. (267.72,298.84)
 .. controls (265.74,300.28) and (261.60,302.27) .. (257.46,302.81)
 .. controls (253.32,303.35) and (253.14,301.37) .. (248.82,298.31)
 .. controls (244.50,295.25) and (238.74,291.65) .. (235.49,287.51)
 .. controls (232.25,283.37) and (230.63,278.33) .. (229.01,272.57)
 .. controls (227.39,266.81) and (232.97,253.85) .. (233.69,252.95)
 .. controls (234.41,252.05) and (235.49,248.27) .. (235.13,244.67)
 .. controls (234.77,241.07) and (231.17,236.03) .. (229.73,231.71)
 .. controls (228.29,227.39) and (226.85,227.03) .. (223.25,224.87)
 .. controls (219.65,222.71) and (213.35,226.31) .. (211.55,226.85)
 .. controls (209.75,227.39) and (206.69,229.91) .. (203.27,229.37)
 .. controls (199.85,228.83) and (192.83,225.41) .. (188.15,221.63)
 .. controls (183.47,217.85) and (186.35,215.51) .. (185.99,208.67)
 .. controls (185.63,201.83) and (184.73,199.31) .. (181.67,194.99)
 .. controls (178.61,190.67) and (172.49,190.31) .. (169.25,190.85)
 .. controls (166.01,191.39) and (158.63,190.13) .. (153.77,188.15)
 .. controls (148.91,186.17) and (141.71,184.01) .. (137.75,179.69)
 .. controls (133.79,175.37) and (132.89,170.87) .. (129.83,164.75)
 .. controls (126.77,158.63) and (122.27,160.25) .. (118.31,159.71)
 .. controls (114.35,159.17) and (107.15,155.21) .. (104.27,153.23)
 .. controls (101.39,151.25) and (95.27,146.75) .. (93.47,145.49)
 .. controls (91.67,144.23) and (85.37,137.57) .. (81.23,132.89)
 .. controls (77.09,128.21) and (69.89,119.21) .. (66.65,117.05)
 .. controls (63.41,114.89) and (53.15,102.29) .. (50.45,98.15)
 .. controls (47.75,94.01) and (31.01,85.55) .. (25.79,82.67)
 .. controls (20.57,79.79) and (15.35,76.55) .. (12.83,74.03)
 .. controls (10.31,71.51) and (8.51,63.59) .. (7.07,59.63)
 .. controls (5.63,55.67) and (1.67,55.85) .. (-2.65,52.97)
 .. controls (-6.97,50.09) and (-8.41,52.07) .. (-10.03,49.73)
 .. controls (-11.65,47.39) and (-28.20,32.44) .. (-30.36,29.92)
 .. controls (-32.52,27.40) and (-37.56,21.82) .. (-39.54,18.22)
 .. controls (-41.52,14.62) and (-47.46,7.78) .. (-49.08,5.44)
 .. controls (-50.70,3.10) and (-55.56,-3.02) .. (-57.00,-5.00)
 .. controls (-58.44,-6.98) and (-65.10,-14.54) .. (-66.54,-15.98)
 .. controls (-67.98,-17.42) and (-71.94,-21.74) .. (-74.82,-26.96)
 .. controls (-77.70,-32.18) and (-78.24,-31.46) .. (-78.60,-35.96)
 .. controls (-78.96,-40.46) and (-77.70,-41.72) .. (-74.46,-44.60)
 .. controls (-71.22,-47.48) and (-70.68,-47.84) .. (-67.26,-47.84)
 .. controls (-63.84,-47.84) and (-63.30,-46.76) .. (-61.86,-46.04)
 .. controls (-60.42,-45.32) and (-58.98,-43.34) .. (-57.36,-40.82)
 .. controls (-55.74,-38.30) and (-53.76,-38.66) .. (-50.16,-33.80)
 .. controls (-46.56,-28.94) and (-44.40,-28.40) .. (-42.24,-25.88)
 .. controls (-40.08,-23.36) and (-40.80,-21.02) .. (-39.00,-17.42)
 .. controls (-37.20,-13.82) and (-36.84,-12.74) .. (-35.76,-9.50)
 .. controls (-34.68,-6.26) and (-35.94,-3.56) .. (-34.86,0.04)
 .. controls (-33.78,3.64) and (-32.16,7.24) .. (-29.28,11.38)
 .. controls (-26.40,15.52) and (-21.72,20.02) .. (-17.76,23.44)
 .. controls (-13.80,26.86) and (-9.48,26.32) .. (-8.04,27.05)
 .. controls (-6.60,27.77) and (-3.00,32.99) .. (-1.56,35.69)
 .. controls (-0.12,38.39) and (0.42,38.03) .. (2.94,41.09)
 .. controls (5.45,44.15) and (9.77,46.49) .. (12.11,47.39)
 .. controls (14.45,48.29) and (17.15,50.09) .. (20.03,52.25)
 .. controls (22.91,54.41) and (22.91,55.13) .. (25.25,56.93)
 .. controls (27.59,58.73) and (35.15,65.21) .. (37.85,68.27)
 .. controls (40.55,71.33) and (49.55,77.99) .. (51.53,79.61)
 .. controls (53.51,81.23) and (74.21,95.09) .. (76.01,98.15)
 .. controls (77.81,101.21) and (92.57,111.11) .. (97.07,113.45)
 .. controls (101.57,115.79) and (108.59,122.81) .. (111.29,125.33)
 .. controls (113.99,127.85) and (117.23,132.35) .. (117.77,135.23)
 .. controls (118.31,138.11) and (120.83,136.85) .. (125.15,137.21)
 .. controls (129.47,137.57) and (133.43,139.73) .. (135.23,140.09)
 .. controls (137.03,140.45) and (140.63,144.23) .. (144.59,146.93)
 .. controls (148.55,149.63) and (151.97,150.71) .. (155.21,154.13)
 .. controls (158.45,157.55) and (161.15,160.25) .. (162.41,164.93)
 .. controls (163.67,169.61) and (162.05,170.51) .. (163.31,173.39)
 .. controls (164.57,176.27) and (166.37,177.17) .. (169.07,177.35)
 .. controls (171.77,177.53) and (174.83,177.89) .. (178.97,179.51)
 .. controls (183.11,181.13) and (184.55,182.39) .. (188.69,184.73)
 .. controls (192.83,187.07) and (196.43,189.59) .. (200.39,192.29)
 .. controls (204.35,194.99) and (207.41,195.89) .. (209.39,198.41)
 .. controls (211.37,200.93) and (210.47,201.29) .. (211.37,206.15)
 .. controls (212.27,211.01) and (216.59,209.93) .. (220.73,211.19)
 .. controls (224.87,212.45) and (225.59,212.63) .. (228.83,213.53)
 .. controls (232.07,214.42) and (237.47,216.94) .. (240.53,217.48)
 .. controls (243.59,218.02) and (246.29,223.06) .. (250.97,225.04)
 .. controls (255.65,227.02) and (256.01,225.76) .. (260.15,225.04)
 .. controls (264.29,224.32) and (268.79,223.78) .. (273.29,221.98)
 .. controls (277.79,220.18) and (282.11,221.44) .. (284.81,222.34)
 .. controls (287.51,223.24) and (293.45,228.82) .. (295.07,231.70)
 .. controls (296.69,234.58) and (304.07,244.12) .. (306.78,250.42)
 .. controls (309.48,256.72) and (305.88,260.50) .. (303.54,264.28)
 .. controls (301.20,268.06) and (298.14,270.40) .. (295.62,272.38)
 .. controls (293.10,274.36) and (288.78,277.60) .. (285.00,278.50)
 .. controls (281.22,279.40) and (282.30,281.92) .. cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((271.50,303.70)
 -- (281.94,291.10)
 -- (293.82,295.78)
 -- (289.50,304.42)
 -- (279.06,310.18)
 -- cycle
));
endfig;
beginfig(21);
draw_upscrap(1)(1,((-460.06,-315.13)
 .. controls (-459.16,-315.32) and (-450.70,-318.92) .. (-441.70,-319.28)
 .. controls (-432.70,-319.64) and (-429.82,-322.34) .. (-424.24,-324.32)
 .. controls (-418.66,-326.30) and (-415.23,-324.32) .. (-407.13,-322.70)
 .. controls (-399.03,-321.08) and (-394.17,-332.78) .. (-392.19,-336.38)
 .. controls (-390.21,-339.98) and (-370.77,-347.36) .. (-362.13,-351.32)
 .. controls (-353.49,-355.28) and (-336.03,-343.58) .. (-330.09,-338.90)
 .. controls (-324.15,-334.22) and (-315.15,-320.36) .. (-311.19,-315.32)
 .. controls (-307.23,-310.28) and (-295.89,-300.92) .. (-293.19,-295.16)
 .. controls (-290.49,-289.40) and (-291.21,-281.66) .. (-287.07,-271.40)
 .. controls (-282.92,-261.14) and (-277.70,-258.26) .. (-274.64,-253.94)
 .. controls (-271.58,-249.62) and (-258.44,-241.70) .. (-255.20,-237.38)
 .. controls (-251.96,-233.06) and (-253.94,-229.46) .. (-249.08,-220.46)
 .. controls (-244.22,-211.46) and (-237.92,-210.02) .. (-235.94,-207.50)
 .. controls (-233.96,-204.98) and (-226.03,-200.48) .. (-223.15,-198.68)
 .. controls (-220.27,-196.88) and (-214.87,-192.56) .. (-211.81,-189.32)
 .. controls (-208.75,-186.08) and (-199.39,-181.58) .. (-195.43,-178.16)
 .. controls (-191.47,-174.74) and (-188.05,-171.32) .. (-183.91,-168.08)
 .. controls (-179.77,-164.84) and (-173.47,-161.06) .. (-170.59,-158.36)
 .. controls (-167.71,-155.66) and (-164.47,-151.52) .. (-158.89,-142.88)
 .. controls (-153.31,-134.24) and (-146.65,-138.20) .. (-141.25,-138.74)
 .. controls (-135.85,-139.28) and (-126.49,-136.58) .. (-116.04,-133.34)
 .. controls (-105.60,-130.10) and (-101.82,-120.38) .. (-97.50,-114.08)
 .. controls (-93.18,-107.78) and (-89.22,-97.52) .. (-87.60,-94.28)
 .. controls (-85.98,-91.04) and (-81.12,-83.84) .. (-79.14,-81.68)
 .. controls (-77.16,-79.52) and (-69.60,-73.22) .. (-67.98,-69.62)
 .. controls (-66.36,-66.02) and (-66.00,-61.16) .. (-63.30,-58.64)
 .. controls (-60.60,-56.12) and (-52.86,-53.60) .. (-49.62,-52.34)
 .. controls (-46.38,-51.08) and (-41.16,-48.20) .. (-34.86,-44.60)
 .. controls (-28.56,-41.00) and (-27.48,-37.40) .. (-26.76,-34.16)
 .. controls (-26.04,-30.92) and (-19.38,-20.84) .. (-15.42,-14.72)
 .. controls (-11.46,-8.60) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.65,39.29) .. (23.81,40.73)
 .. controls (25.97,42.17) and (29.39,45.77) .. (37.31,47.57)
 .. controls (45.23,49.37) and (61.07,61.43) .. (63.77,65.39)
 .. controls (66.47,69.35) and (91.31,86.09) .. (94.37,88.43)
 .. controls (97.43,90.77) and (111.65,108.77) .. (114.53,112.01)
 .. controls (117.41,115.25) and (120.47,123.71) .. (122.99,125.51)
 .. controls (125.51,127.31) and (126.05,132.35) .. (131.27,133.61)
 .. controls (136.49,134.87) and (140.27,133.25) .. (144.95,133.43)
 .. controls (149.63,133.61) and (157.73,141.35) .. (161.15,145.67)
 .. controls (164.57,149.99) and (180.41,161.33) .. (184.37,164.03)
 .. controls (188.33,166.73) and (204.89,175.73) .. (212.63,180.77)
 .. controls (220.37,185.81) and (240.71,201.46) .. (251.87,211.00)
 .. controls (263.03,220.54) and (269.15,215.32) .. (273.29,214.42)
 .. controls (277.43,213.52) and (283.91,214.60) .. (291.83,216.76)
 .. controls (299.75,218.92) and (310.73,234.04) .. (310.37,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
),
1,((280.32,318.82)
 .. controls (276.18,313.96) and (272.94,311.08) .. (266.82,307.30)
 .. controls (260.70,303.53) and (258.72,305.15) .. (253.50,304.07)
 .. controls (248.28,302.99) and (241.08,298.85) .. (237.30,293.63)
 .. controls (233.51,288.41) and (226.49,284.81) .. (225.05,279.95)
 .. controls (223.61,275.09) and (227.21,270.77) .. (218.93,262.31)
 .. controls (210.65,253.85) and (201.83,245.57) .. (197.69,242.33)
 .. controls (193.55,239.09) and (187.97,231.17) .. (181.13,226.49)
 .. controls (174.29,221.81) and (159.53,213.53) .. (155.39,208.31)
 .. controls (151.25,203.09) and (143.33,196.97) .. (140.27,191.93)
 .. controls (137.21,186.89) and (127.67,175.37) .. (121.91,171.59)
 .. controls (116.15,167.81) and (108.77,163.85) .. (102.29,157.91)
 .. controls (95.81,151.97) and (86.45,144.95) .. (79.97,141.35)
 .. controls (73.49,137.75) and (60.71,129.29) .. (54.41,122.27)
 .. controls (48.11,115.25) and (43.25,106.25) .. (36.77,101.93)
 .. controls (30.29,97.61) and (18.59,90.23) .. (11.57,79.79)
 .. controls (4.55,69.35) and (0.77,59.45) .. (-2.83,57.29)
 .. controls (-6.43,55.13) and (-18.85,49.18) .. (-22.09,45.22)
 .. controls (-25.33,41.26) and (-47.10,24.52) .. (-49.44,19.84)
 .. controls (-51.78,15.16) and (-66.90,-4.82) .. (-69.96,-9.86)
 .. controls (-73.02,-14.90) and (-76.98,-23.90) .. (-86.16,-26.60)
 .. controls (-95.34,-29.30) and (-104.16,-26.42) .. (-112.44,-33.44)
 .. controls (-120.72,-40.46) and (-126.84,-45.86) .. (-128.28,-47.84)
 .. controls (-129.72,-49.82) and (-136.20,-50.72) .. (-138.18,-51.08)
 .. controls (-140.16,-51.44) and (-143.40,-54.13) .. (-144.84,-59.53)
 .. controls (-146.28,-64.93) and (-150.24,-75.02) .. (-154.92,-79.52)
 .. controls (-159.60,-84.02) and (-159.96,-90.86) .. (-164.82,-94.46)
 .. controls (-169.69,-98.06) and (-175.63,-101.66) .. (-176.71,-104.90)
 .. controls (-177.79,-108.14) and (-179.95,-118.58) .. (-181.93,-120.92)
 .. controls (-183.91,-123.26) and (-196.15,-131.72) .. (-199.03,-133.52)
 .. controls (-201.91,-135.32) and (-211.09,-147.38) .. (-214.15,-148.10)
 .. controls (-217.22,-148.82) and (-221.90,-147.38) .. (-227.48,-152.96)
 .. controls (-233.06,-158.54) and (-235.94,-161.96) .. (-239.36,-164.30)
 .. controls (-242.78,-166.64) and (-248.90,-170.78) .. (-251.60,-171.50)
 .. controls (-254.30,-172.22) and (-257.72,-176.18) .. (-260.60,-176.18)
 .. controls (-263.48,-176.18) and (-266.00,-177.44) .. (-269.78,-177.44)
),
1,((-248.72,-170.42)
 .. controls (-248.18,-169.16) and (-247.10,-164.66) .. (-245.84,-159.98)
 .. controls (-244.58,-155.30) and (-247.10,-146.66) .. (-247.28,-140.90)
 .. controls (-247.46,-135.14) and (-247.64,-125.97) .. (-248.18,-120.93)
 .. controls (-248.73,-115.89) and (-245.49,-101.85) .. (-244.77,-98.61)
 .. controls (-244.05,-95.37) and (-237.93,-79.89) .. (-233.79,-77.01)
 .. controls (-229.65,-74.13) and (-215.25,-52.35) .. (-213.45,-47.31)
 .. controls (-211.65,-42.27) and (-202.37,-20.21) .. (-201.11,-15.89)
),
1,((-201.11,-15.89)
 .. controls (-199.85,-11.57) and (-195.26,3.46) .. (-190.40,11.02)
 .. controls (-185.53,18.58) and (-175.81,36.94) .. (-172.93,41.62)
 .. controls (-170.05,46.30) and (-154.57,75.28) .. (-153.31,78.16)
 .. controls (-152.05,81.04) and (-146.83,107.50) .. (-140.89,127.84)
 .. controls (-138.00,137.73) and (-138.10,149.98) .. (-138.86,156.06)
),
0,reverse ((-254.65,232.24)
 .. controls (-254.65,232.24) and (-256.45,232.42) .. (-251.59,228.82)
 .. controls (-246.73,225.22) and (-241.15,211.90) .. (-241.33,201.64)
 .. controls (-241.51,191.38) and (-244.75,167.08) .. (-242.41,165.64)
 .. controls (-240.07,164.20) and (-240.61,163.30) .. (-233.59,161.14)
 .. controls (-226.57,158.98) and (-220.99,158.80) .. (-216.85,158.26)
 .. controls (-212.71,157.72) and (-200.65,157.72) .. (-198.67,157.90)
 .. controls (-196.69,158.08) and (-173.83,158.62) .. (-170.95,157.72)
 .. controls (-168.07,156.82) and (-166.63,156.28) .. (-163.03,155.38)
 .. controls (-159.43,154.48) and (-152.59,152.86) .. (-147.19,153.94)
 .. controls (-141.79,155.02) and (-137.65,156.46) .. (-137.65,156.46)
),
1,((-254.65,232.24)
 .. controls (-251.05,237.64) and (-275.53,195.16) .. (-277.87,176.62)
 .. controls (-278.71,169.92) and (-280.39,155.20) .. (-280.57,147.82)
 .. controls (-280.79,138.77) and (-283.63,117.94) .. (-282.37,115.24)
 .. controls (-281.11,112.54) and (-282.55,106.24) .. (-282.55,101.02)
 .. controls (-282.55,95.80) and (-283.99,79.24) .. (-284.17,76.54)
 .. controls (-284.35,73.84) and (-288.86,32.26) .. (-290.30,21.64)
 .. controls (-291.74,11.02) and (-289.76,-15.44) .. (-288.68,-19.94)
),
1,((-288.68,-19.94)
 .. controls (-287.60,-24.44) and (-283.46,-54.69) .. (-282.56,-57.39)
 .. controls (-281.66,-60.09) and (-283.46,-95.19) .. (-284.36,-100.05)
 .. controls (-285.26,-104.91) and (-291.38,-127.76) .. (-292.64,-131.00)
 .. controls (-293.90,-134.24) and (-296.96,-147.02) .. (-298.40,-150.08)
 .. controls (-299.84,-153.14) and (-305.78,-164.66) .. (-307.22,-167.54)
 .. controls (-308.66,-170.42) and (-310.46,-170.96) .. (-316.94,-168.80)
),
1,((-316.94,-168.80)
 -- (-322.16,-163.94)
),
1,((-329.00,-172.94)
 .. controls (-335.48,-170.78) and (-321.26,-174.38) .. (-321.08,-176.18)
 .. controls (-320.90,-177.98) and (-318.38,-185.90) .. (-318.38,-190.22)
 .. controls (-318.38,-194.54) and (-321.09,-198.14) .. (-323.07,-201.92)
 .. controls (-325.05,-205.70) and (-332.61,-208.22) .. (-338.01,-209.84)
 .. controls (-343.41,-211.46) and (-354.39,-211.46) .. (-358.35,-211.10)
 .. controls (-362.31,-210.74) and (-380.85,-215.06) .. (-384.27,-216.32)
 .. controls (-387.69,-217.58) and (-411.99,-226.93) .. (-428.01,-236.29)
 .. controls (-444.03,-245.65) and (-442.05,-259.15) .. (-444.03,-265.27)
 .. controls (-446.01,-271.39) and (-447.99,-284.89) .. (-448.35,-289.03)
 .. controls (-448.72,-293.17) and (-454.66,-288.31) .. (-458.26,-288.85)
));
draw_downscrap;
endfig;
beginfig(22);
ATTR__height := -1;
drawoptions();
l_wall_invisible(((-254.65,232.24)
 .. controls (-254.65,232.24) and (-256.45,232.42) .. (-251.59,228.82)
 .. controls (-246.73,225.22) and (-241.15,211.90) .. (-241.33,201.64)
 .. controls (-241.51,191.38) and (-244.75,167.08) .. (-242.41,165.64)
 .. controls (-240.07,164.20) and (-240.61,163.30) .. (-233.59,161.14)
 .. controls (-226.57,158.98) and (-220.99,158.80) .. (-216.85,158.26)
 .. controls (-212.71,157.72) and (-200.65,157.72) .. (-198.67,157.90)
 .. controls (-196.69,158.08) and (-173.83,158.62) .. (-170.95,157.72)
 .. controls (-168.07,156.82) and (-166.63,156.28) .. (-163.03,155.38)
 .. controls (-159.43,154.48) and (-152.59,152.86) .. (-147.19,153.94)
 .. controls (-141.79,155.02) and (-137.65,156.46) .. (-137.65,156.46)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-254.65,232.24)
 .. controls (-251.05,237.64) and (-275.53,195.16) .. (-277.87,176.62)
 .. controls (-278.71,169.92) and (-280.39,155.20) .. (-280.57,147.82)
 .. controls (-280.79,138.77) and (-283.63,117.94) .. (-282.37,115.24)
 .. controls (-281.11,112.54) and (-282.55,106.24) .. (-282.55,101.02)
 .. controls (-282.55,95.80) and (-283.99,79.24) .. (-284.17,76.54)
 .. controls (-284.35,73.84) and (-288.86,32.26) .. (-290.30,21.64)
 .. controls (-291.74,11.02) and (-289.76,-15.44) .. (-288.68,-19.94)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-201.11,-15.89)
 .. controls (-199.85,-11.57) and (-195.26,3.46) .. (-190.40,11.02)
 .. controls (-185.53,18.58) and (-175.81,36.94) .. (-172.93,41.62)
 .. controls (-170.05,46.30) and (-154.57,75.28) .. (-153.31,78.16)
 .. controls (-152.05,81.04) and (-146.83,107.50) .. (-140.89,127.84)
 .. controls (-138.00,137.73) and (-138.10,149.98) .. (-138.86,156.06)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-288.68,-19.94)
 .. controls (-287.60,-24.44) and (-283.46,-54.69) .. (-282.56,-57.39)
 .. controls (-281.66,-60.09) and (-283.46,-95.19) .. (-284.36,-100.05)
 .. controls (-285.26,-104.91) and (-291.38,-127.76) .. (-292.64,-131.00)
 .. controls (-293.90,-134.24) and (-296.96,-147.02) .. (-298.40,-150.08)
 .. controls (-299.84,-153.14) and (-305.78,-164.66) .. (-307.22,-167.54)
 .. controls (-308.66,-170.42) and (-310.46,-170.96) .. (-316.94,-168.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-329.00,-172.94)
 .. controls (-335.48,-170.78) and (-321.26,-174.38) .. (-321.08,-176.18)
 .. controls (-320.90,-177.98) and (-318.38,-185.90) .. (-318.38,-190.22)
 .. controls (-318.38,-194.54) and (-321.09,-198.14) .. (-323.07,-201.92)
 .. controls (-325.05,-205.70) and (-332.61,-208.22) .. (-338.01,-209.84)
 .. controls (-343.41,-211.46) and (-354.39,-211.46) .. (-358.35,-211.10)
 .. controls (-362.31,-210.74) and (-380.85,-215.06) .. (-384.27,-216.32)
 .. controls (-387.69,-217.58) and (-411.99,-226.93) .. (-428.01,-236.29)
 .. controls (-444.03,-245.65) and (-442.05,-259.15) .. (-444.03,-265.27)
 .. controls (-446.01,-271.39) and (-447.99,-284.89) .. (-448.35,-289.03)
 .. controls (-448.72,-293.17) and (-454.66,-288.31) .. (-458.26,-288.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-316.94,-168.80)
 -- (-322.16,-163.94)
));
drawoptions();
p_gradient((-433.05,-305.42),85.6,1.41,(0,0));
drawoptions();
p_gradient((-315.32,-174.38),60.6,1.00,(0,0));
ATTR__id := "l261-3264-5728";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-248.72,-170.42)
 .. controls (-248.18,-169.16) and (-247.10,-164.66) .. (-245.84,-159.98)
 .. controls (-244.58,-155.30) and (-247.10,-146.66) .. (-247.28,-140.90)
 .. controls (-247.46,-135.14) and (-247.64,-125.97) .. (-248.18,-120.93)
 .. controls (-248.73,-115.89) and (-245.49,-101.85) .. (-244.77,-98.61)
 .. controls (-244.05,-95.37) and (-237.93,-79.89) .. (-233.79,-77.01)
 .. controls (-229.65,-74.13) and (-215.25,-52.35) .. (-213.45,-47.31)
 .. controls (-211.65,-42.27) and (-202.37,-20.21) .. (-201.11,-15.89)
));
ATTR__id := "";
drawoptions();
p_pillar((-423.33,-260.41),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-419.01,-307.94),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-384.81,-322.70),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-389.13,-240.26),0.0,1.00,(0,0));
drawoptions();
p_waterflow_permanent((-137.46,-99.14),120.5,1.00,(0,0));
drawoptions();
p_waterflow_permanent((-259.16,-191.66),112.6,1.00,(0,0));
drawoptions();
p_waterflow_permanent((-225.31,-185.18),112.6,1.00,(0,0));
drawoptions();
p_waterflow_permanent((-102.18,-60.62),120.5,1.00,(0,0));
drawoptions();
p_waterflow_permanent((-269.60,-262.58),210.9,1.00,(0,0));
ATTR__id := "l86-5372-7218";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((280.32,318.82)
 .. controls (276.18,313.96) and (272.94,311.08) .. (266.82,307.30)
 .. controls (260.70,303.53) and (258.72,305.15) .. (253.50,304.07)
 .. controls (248.28,302.99) and (241.08,298.85) .. (237.30,293.63)
 .. controls (233.51,288.41) and (226.49,284.81) .. (225.05,279.95)
 .. controls (223.61,275.09) and (227.21,270.77) .. (218.93,262.31)
 .. controls (210.65,253.85) and (201.83,245.57) .. (197.69,242.33)
 .. controls (193.55,239.09) and (187.97,231.17) .. (181.13,226.49)
 .. controls (174.29,221.81) and (159.53,213.53) .. (155.39,208.31)
 .. controls (151.25,203.09) and (143.33,196.97) .. (140.27,191.93)
 .. controls (137.21,186.89) and (127.67,175.37) .. (121.91,171.59)
 .. controls (116.15,167.81) and (108.77,163.85) .. (102.29,157.91)
 .. controls (95.81,151.97) and (86.45,144.95) .. (79.97,141.35)
 .. controls (73.49,137.75) and (60.71,129.29) .. (54.41,122.27)
 .. controls (48.11,115.25) and (43.25,106.25) .. (36.77,101.93)
 .. controls (30.29,97.61) and (18.59,90.23) .. (11.57,79.79)
 .. controls (4.55,69.35) and (0.77,59.45) .. (-2.83,57.29)
 .. controls (-6.43,55.13) and (-18.85,49.18) .. (-22.09,45.22)
 .. controls (-25.33,41.26) and (-47.10,24.52) .. (-49.44,19.84)
 .. controls (-51.78,15.16) and (-66.90,-4.82) .. (-69.96,-9.86)
 .. controls (-73.02,-14.90) and (-76.98,-23.90) .. (-86.16,-26.60)
 .. controls (-95.34,-29.30) and (-104.16,-26.42) .. (-112.44,-33.44)
 .. controls (-120.72,-40.46) and (-126.84,-45.86) .. (-128.28,-47.84)
 .. controls (-129.72,-49.82) and (-136.20,-50.72) .. (-138.18,-51.08)
 .. controls (-140.16,-51.44) and (-143.40,-54.13) .. (-144.84,-59.53)
 .. controls (-146.28,-64.93) and (-150.24,-75.02) .. (-154.92,-79.52)
 .. controls (-159.60,-84.02) and (-159.96,-90.86) .. (-164.82,-94.46)
 .. controls (-169.69,-98.06) and (-175.63,-101.66) .. (-176.71,-104.90)
 .. controls (-177.79,-108.14) and (-179.95,-118.58) .. (-181.93,-120.92)
 .. controls (-183.91,-123.26) and (-196.15,-131.72) .. (-199.03,-133.52)
 .. controls (-201.91,-135.32) and (-211.09,-147.38) .. (-214.15,-148.10)
 .. controls (-217.22,-148.82) and (-221.90,-147.38) .. (-227.48,-152.96)
 .. controls (-233.06,-158.54) and (-235.94,-161.96) .. (-239.36,-164.30)
 .. controls (-242.78,-166.64) and (-248.90,-170.78) .. (-251.60,-171.50)
 .. controls (-254.30,-172.22) and (-257.72,-176.18) .. (-260.60,-176.18)
 .. controls (-263.48,-176.18) and (-266.00,-177.44) .. (-269.78,-177.44)
));
ATTR__id := "l87-5698-7070";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-460.06,-315.13)
 .. controls (-459.16,-315.32) and (-450.70,-318.92) .. (-441.70,-319.28)
 .. controls (-432.70,-319.64) and (-429.82,-322.34) .. (-424.24,-324.32)
 .. controls (-418.66,-326.30) and (-415.23,-324.32) .. (-407.13,-322.70)
 .. controls (-399.03,-321.08) and (-394.17,-332.78) .. (-392.19,-336.38)
 .. controls (-390.21,-339.98) and (-370.77,-347.36) .. (-362.13,-351.32)
 .. controls (-353.49,-355.28) and (-336.03,-343.58) .. (-330.09,-338.90)
 .. controls (-324.15,-334.22) and (-315.15,-320.36) .. (-311.19,-315.32)
 .. controls (-307.23,-310.28) and (-295.89,-300.92) .. (-293.19,-295.16)
 .. controls (-290.49,-289.40) and (-291.21,-281.66) .. (-287.07,-271.40)
 .. controls (-282.92,-261.14) and (-277.70,-258.26) .. (-274.64,-253.94)
 .. controls (-271.58,-249.62) and (-258.44,-241.70) .. (-255.20,-237.38)
 .. controls (-251.96,-233.06) and (-253.94,-229.46) .. (-249.08,-220.46)
 .. controls (-244.22,-211.46) and (-237.92,-210.02) .. (-235.94,-207.50)
 .. controls (-233.96,-204.98) and (-226.03,-200.48) .. (-223.15,-198.68)
 .. controls (-220.27,-196.88) and (-214.87,-192.56) .. (-211.81,-189.32)
 .. controls (-208.75,-186.08) and (-199.39,-181.58) .. (-195.43,-178.16)
 .. controls (-191.47,-174.74) and (-188.05,-171.32) .. (-183.91,-168.08)
 .. controls (-179.77,-164.84) and (-173.47,-161.06) .. (-170.59,-158.36)
 .. controls (-167.71,-155.66) and (-164.47,-151.52) .. (-158.89,-142.88)
 .. controls (-153.31,-134.24) and (-146.65,-138.20) .. (-141.25,-138.74)
 .. controls (-135.85,-139.28) and (-126.49,-136.58) .. (-116.04,-133.34)
 .. controls (-105.60,-130.10) and (-101.82,-120.38) .. (-97.50,-114.08)
 .. controls (-93.18,-107.78) and (-89.22,-97.52) .. (-87.60,-94.28)
 .. controls (-85.98,-91.04) and (-81.12,-83.84) .. (-79.14,-81.68)
 .. controls (-77.16,-79.52) and (-69.60,-73.22) .. (-67.98,-69.62)
 .. controls (-66.36,-66.02) and (-66.00,-61.16) .. (-63.30,-58.64)
 .. controls (-60.60,-56.12) and (-52.86,-53.60) .. (-49.62,-52.34)
 .. controls (-46.38,-51.08) and (-41.16,-48.20) .. (-34.86,-44.60)
 .. controls (-28.56,-41.00) and (-27.48,-37.40) .. (-26.76,-34.16)
 .. controls (-26.04,-30.92) and (-19.38,-20.84) .. (-15.42,-14.72)
 .. controls (-11.46,-8.60) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.65,39.29) .. (23.81,40.73)
 .. controls (25.97,42.17) and (29.39,45.77) .. (37.31,47.57)
 .. controls (45.23,49.37) and (61.07,61.43) .. (63.77,65.39)
 .. controls (66.47,69.35) and (91.31,86.09) .. (94.37,88.43)
 .. controls (97.43,90.77) and (111.65,108.77) .. (114.53,112.01)
 .. controls (117.41,115.25) and (120.47,123.71) .. (122.99,125.51)
 .. controls (125.51,127.31) and (126.05,132.35) .. (131.27,133.61)
 .. controls (136.49,134.87) and (140.27,133.25) .. (144.95,133.43)
 .. controls (149.63,133.61) and (157.73,141.35) .. (161.15,145.67)
 .. controls (164.57,149.99) and (180.41,161.33) .. (184.37,164.03)
 .. controls (188.33,166.73) and (204.89,175.73) .. (212.63,180.77)
 .. controls (220.37,185.81) and (240.71,201.46) .. (251.87,211.00)
 .. controls (263.03,220.54) and (269.15,215.32) .. (273.29,214.42)
 .. controls (277.43,213.52) and (283.91,214.60) .. (291.83,216.76)
 .. controls (299.75,218.92) and (310.73,234.04) .. (310.37,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
));
ATTR__id := "";
drawoptions();
p_entrance((319.02,313.06),129.9,2.00,(0,0));
endfig;
beginfig(23);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char49 \char50 \mainfont{} etex,(-173.11,-6.62),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char116 \char114 \char97 \char118 \char101 \char114 \char115 \char101 \mainfont{} etex,(-133.50,27.58),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char53 \mainfont{} etex,(-119.11,153.94),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char104 \char108 \char63 \mainfont{} etex,(-472.66,-302.89),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char104 \char108 \char63 \mainfont{} etex,(-332.60,-157.45),0.0,0);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char82 \char111 \char109 \char101 \char111 \ \char67 \char97 \char118 \char101 \mainfont{} etex,(472.38,355.90),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \vbox{\halign{#\hfil\cr\thfb\char112 \char56 \cr\thfb \char74 \char117 \char108 \char105 \char101 \char116 \cr}}\mainfont{} etex,(-235.76,-268.70),0.0,0);
endfig;
background:=(0.28750,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.28750, 1.00000, 0.25000);
current_scrap := "Romeo_21_1SP1@Romeo_21_1.romeo";
ATTR__scrap := "Romeo_21_1SP1";
beginfig(24);
ATTR__survey := "Romeo_21_1.romeo";
current_src := "Romeo_21_1.th2 [584]";
string area_border[];
area_border[1] := "l70-4846-3556";
drawoptions();
a_water(buildcycle(((257.86,145.96)
 .. controls (257.86,145.96) and (245.98,128.32) .. (249.58,115.37)
 .. controls (253.18,102.41) and (314.38,91.24) .. (314.38,91.24)
 -- (355.78,106.72)
 -- (396.10,130.12)
 -- (411.94,151.72)
 -- (434.98,183.03)
 -- (439.30,216.87)
 -- (401.50,213.27)
 -- (378.46,220.11)
 -- (350.02,235.95)
 -- (326.62,246.40)
 .. controls (326.62,246.40) and (306.10,256.48) .. (303.58,257.20)
 .. controls (301.06,257.92) and (243.47,261.88) .. (292.42,235.24)
 .. controls (341.38,208.60) and (334.54,225.88) .. (352.90,202.48)
 .. controls (371.26,179.08) and (379.90,170.80) .. (374.86,163.96)
 .. controls (369.82,157.12) and (334.18,148.48) .. (334.18,148.48)
 -- (313.66,143.44)
 -- (285.22,142.72)
 -- cycle
)));
current_src := "Romeo_21_1.th2 [568]";
string area_border[];
area_border[1] := "l72-4700-3940";
drawoptions();
a_blocks(buildcycle(((349.66,277.35)
 .. controls (349.66,277.35) and (343.54,271.23) .. (329.50,251.79)
 .. controls (311.10,226.31) and (329.86,214.36) .. (341.02,203.56)
 .. controls (352.18,192.76) and (364.06,203.20) .. (374.50,213.27)
 .. controls (384.94,223.35) and (368.38,244.23) .. (380.98,253.23)
 .. controls (393.58,262.23) and (403.66,275.91) .. (398.98,284.55)
 .. controls (394.30,293.19) and (396.10,311.55) .. (378.46,298.59)
 .. controls (362.51,286.87) and (349.66,277.35) .. cycle
)));
current_src := "Romeo_21_1.th2 [519]";
string area_border[];
area_border[1] := "l39-2072-1684";
drawoptions();
a_water(buildcycle(((-290.41,-199.26)
 .. controls (-290.41,-199.26) and (-284.65,-194.22) .. (-324.25,-224.46)
 .. controls (-363.85,-254.70) and (-314.63,-327.32) .. (-285.37,-337.50)
 .. controls (-268.81,-343.26) and (-151.45,-274.86) .. (-125.53,-270.54)
 .. controls (-99.61,-266.22) and (77.49,-250.38) .. (57.33,-207.90)
 .. controls (37.17,-165.42) and (-18.26,-141.66) .. (-28.34,-131.58)
 .. controls (-38.42,-121.50) and (-106.09,-90.55) .. (-147.85,-150.31)
 .. controls (-189.61,-210.07) and (-290.41,-199.26) .. cycle
)));
current_src := "Romeo_21_1.th2 [370]";
string area_border[];
area_border[1] := "l52-1412-2752";
drawoptions();
a_water(buildcycle(((-238.56,64.97)
 .. controls (-246.42,53.04) and (-263.04,26.81) .. (-231.36,38.33)
 .. controls (-198.14,50.41) and (-217.67,96.65) .. cycle
)));
current_src := "Romeo_21_1.th2 [347]";
string area_border[];
area_border[1] := "l56-2286-4414";
drawoptions();
a_water(buildcycle(((-79.80,368.80)
 .. controls (-79.80,368.80) and (-101.40,361.24) .. (-78.01,352.60)
 .. controls (-58.02,345.22) and (-59.29,380.68) .. (-79.80,368.80)
)));
current_src := "Romeo_21_1.th2 [343]";
string area_border[];
area_border[1] := "l54-3708-3228";
drawoptions();
a_blocks(buildcycle(((132.94,98.81)
 .. controls (132.94,98.81) and (159.57,81.53) .. (170.37,97.37)
 .. controls (181.18,113.21) and (192.70,142.01) .. (189.82,150.65)
 .. controls (186.94,159.29) and (169.66,167.21) .. (161.02,167.21)
 .. controls (152.38,167.21) and (132.94,98.81) .. cycle
)));
current_src := "Romeo_21_1.th2 [339]";
string area_border[];
area_border[1] := "l50-3512-2528";
drawoptions();
a_water(buildcycle(((145.89,31.85)
 .. controls (123.15,21.90) and (136.23,16.79) .. (125.73,0.17)
 .. controls (117.09,-13.51) and (142.29,-19.27) .. (154.53,-3.43)
 .. controls (176.12,24.51) and (180.45,46.97) .. cycle
)));
current_src := "Romeo_21_1.th2 [284]";
string area_border[];
area_border[1] := "l46-700-912";
drawoptions();
a_sump(buildcycle(((-373.21,-264.06)
 .. controls (-373.21,-264.06) and (-257.65,-238.86) .. (-280.69,-346.14)
 .. controls (-304.96,-459.16) and (-438.72,-327.42) .. (-414.25,-313.74)
 .. controls (-408.45,-310.50) and (-373.21,-264.06) .. cycle
)));
current_src := "Romeo_21_1.th2 [272]";
string area_border[];
area_border[1] := "l78-4440-3102";
drawoptions();
a_sump(buildcycle(((310.06,131.56)
 -- (338.14,92.68)
 -- (374.50,105.64)
 -- (344.98,160.72)
 -- cycle
)));
current_src := "Romeo_21_1.th2 [223]";
string area_border[];
area_border[1] := "l68-3938-4174";
drawoptions();
a_blocks(buildcycle(((211.07,316.60)
 -- (238.79,253.60)
 -- (268.67,268.72)
 -- (229.43,332.80)
 -- cycle
)));
current_src := "Romeo_21_1.th2 [202]";
string area_border[];
area_border[1] := "l73-3856-3242";
drawoptions();
a_debris(buildcycle(((190.89,103.13)
 -- (198.46,157.13)
 -- (238.78,169.00)
 -- (247.06,169.00)
 -- (233.02,108.53)
 -- cycle
)));
current_src := "Romeo_21_1.th2 [198]";
string area_border[];
area_border[1] := "l70-4074-3714";
drawoptions();
a_debris(buildcycle(((189.46,216.88)
 -- (221.50,180.16)
 -- (259.66,201.04)
 -- (256.79,249.28)
 -- cycle
)));
current_src := "Romeo_21_1.th2 [54]";
string area_border[];
area_border[1] := "l47-3074-4871";
drawoptions();
a_blocks(buildcycle(((-2.77,439.72)
 .. controls (13.07,431.26) and (10.55,420.46) .. (36.29,421.54)
 .. controls (62.03,422.63) and (69.95,431.09) .. (70.67,439.73)
 .. controls (71.39,448.37) and (68.87,457.19) .. (66.53,457.55)
 .. controls (64.19,457.91) and (-18.61,448.18) .. cycle
)));
ATTR__id := "l72-4700-3940";
ATTR__height := -1;
drawoptions();
l_border_invisible(((349.66,277.35)
 .. controls (349.66,277.35) and (343.54,271.23) .. (329.50,251.79)
 .. controls (311.10,226.31) and (329.86,214.36) .. (341.02,203.56)
 .. controls (352.18,192.76) and (364.06,203.20) .. (374.50,213.27)
 .. controls (384.94,223.35) and (368.38,244.23) .. (380.98,253.23)
 .. controls (393.58,262.23) and (403.66,275.91) .. (398.98,284.55)
 .. controls (394.30,293.19) and (396.10,311.55) .. (378.46,298.59)
 .. controls (362.51,286.87) and (349.66,277.35) .. cycle
));
ATTR__id := "l70-4846-3556";
ATTR__height := -1;
drawoptions();
l_border_invisible(((257.86,145.96)
 .. controls (257.86,145.96) and (245.98,128.32) .. (249.58,115.37)
 .. controls (253.18,102.41) and (314.38,91.24) .. (314.38,91.24)
 -- (355.78,106.72)
 -- (396.10,130.12)
 -- (411.94,151.72)
 -- (434.98,183.03)
 -- (439.30,216.87)
 -- (401.50,213.27)
 -- (378.46,220.11)
 -- (350.02,235.95)
 -- (326.62,246.40)
 .. controls (326.62,246.40) and (306.10,256.48) .. (303.58,257.20)
 .. controls (301.06,257.92) and (243.47,261.88) .. (292.42,235.24)
 .. controls (341.38,208.60) and (334.54,225.88) .. (352.90,202.48)
 .. controls (371.26,179.08) and (379.90,170.80) .. (374.86,163.96)
 .. controls (369.82,157.12) and (334.18,148.48) .. (334.18,148.48)
 -- (313.66,143.44)
 -- (285.22,142.72)
 -- cycle
));
ATTR__id := "l39-2072-1684";
ATTR__height := -1;
drawoptions();
l_border_visible(((-290.41,-199.26)
 .. controls (-290.41,-199.26) and (-284.65,-194.22) .. (-324.25,-224.46)
 .. controls (-363.85,-254.70) and (-314.63,-327.32) .. (-285.37,-337.50)
 .. controls (-268.81,-343.26) and (-151.45,-274.86) .. (-125.53,-270.54)
 .. controls (-99.61,-266.22) and (77.49,-250.38) .. (57.33,-207.90)
 .. controls (37.17,-165.42) and (-18.26,-141.66) .. (-28.34,-131.58)
 .. controls (-38.42,-121.50) and (-106.09,-90.55) .. (-147.85,-150.31)
 .. controls (-189.61,-210.07) and (-290.41,-199.26) .. cycle
));
ATTR__id := "l50-3512-2528";
ATTR__height := -1;
drawoptions();
l_border_visible(((145.89,31.85)
 .. controls (123.15,21.90) and (136.23,16.79) .. (125.73,0.17)
 .. controls (117.09,-13.51) and (142.29,-19.27) .. (154.53,-3.43)
 .. controls (176.12,24.51) and (180.45,46.97) .. cycle
));
ATTR__id := "l52-1412-2752";
ATTR__height := -1;
drawoptions();
l_border_visible(((-238.56,64.97)
 .. controls (-246.42,53.04) and (-263.04,26.81) .. (-231.36,38.33)
 .. controls (-198.14,50.41) and (-217.67,96.65) .. cycle
));
ATTR__id := "l54-3708-3228";
ATTR__height := -1;
drawoptions();
l_border_invisible(((132.94,98.81)
 .. controls (132.94,98.81) and (159.57,81.53) .. (170.37,97.37)
 .. controls (181.18,113.21) and (192.70,142.01) .. (189.82,150.65)
 .. controls (186.94,159.29) and (169.66,167.21) .. (161.02,167.21)
 .. controls (152.38,167.21) and (132.94,98.81) .. cycle
));
ATTR__id := "l56-2286-4414";
ATTR__height := -1;
drawoptions();
l_border_visible(((-79.80,368.80)
 .. controls (-79.80,368.80) and (-101.40,361.24) .. (-78.01,352.60)
 .. controls (-58.02,345.22) and (-59.29,380.68) .. (-79.80,368.80)
));
ATTR__id := "l46-700-912";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-373.21,-264.06)
 .. controls (-373.21,-264.06) and (-257.65,-238.86) .. (-280.69,-346.14)
 .. controls (-304.96,-459.16) and (-438.72,-327.42) .. (-414.25,-313.74)
 .. controls (-408.45,-310.50) and (-373.21,-264.06) .. cycle
));
ATTR__id := "l78-4440-3102";
ATTR__height := -1;
drawoptions();
l_border_invisible(((310.06,131.56)
 -- (338.14,92.68)
 -- (374.50,105.64)
 -- (344.98,160.72)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((290.99,278.44)
 -- (302.87,282.04)
 -- (307.55,267.64)
 -- (296.39,260.80)
 -- cycle
));
ATTR__id := "l68-3938-4174";
ATTR__height := -1;
drawoptions();
l_border_invisible(((211.07,316.60)
 -- (238.79,253.60)
 -- (268.67,268.72)
 -- (229.43,332.80)
 -- cycle
));
ATTR__id := "l70-4074-3714";
ATTR__height := -1;
drawoptions();
l_border_invisible(((189.46,216.88)
 -- (221.50,180.16)
 -- (259.66,201.04)
 -- (256.79,249.28)
 -- cycle
));
ATTR__id := "l73-3856-3242";
ATTR__height := -1;
drawoptions();
l_border_invisible(((190.89,103.13)
 -- (198.46,157.13)
 -- (238.78,169.00)
 -- (247.06,169.00)
 -- (233.02,108.53)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-88.27,332.26)
 .. controls (-88.27,332.26) and (-97.45,343.38) .. (-81.61,342.70)
 .. controls (-74.80,342.41) and (-75.09,346.29) .. (-69.91,339.64)
 .. controls (-60.37,327.40) and (-74.41,332.44) .. (-79.45,328.48)
 .. controls (-83.20,325.53) and (-88.27,332.26) .. cycle
));
ATTR__id := "l47-3074-4871";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-2.77,439.72)
 .. controls (13.07,431.26) and (10.55,420.46) .. (36.29,421.54)
 .. controls (62.03,422.63) and (69.95,431.09) .. (70.67,439.73)
 .. controls (71.39,448.37) and (68.87,457.19) .. (66.53,457.55)
 .. controls (64.19,457.91) and (-18.61,448.18) .. cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((107.03,401.92)
 .. controls (107.03,401.92) and (113.33,404.26) .. (114.95,403.00)
 .. controls (116.57,401.74) and (119.99,394.36) .. (119.99,394.36)
 -- (109.55,392.38)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((15.95,374.74)
 -- (19.55,364.48)
 -- (28.55,367.00)
 -- (25.13,375.10)
 -- cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((34.85,370.60)
 -- (43.31,371.32)
 -- (42.59,377.44)
 .. controls (42.59,377.44) and (38.09,378.70) .. (37.37,378.52)
 .. controls (36.65,378.34) and (32.15,378.70) .. (32.15,378.70)
 -- cycle
));
endfig;
beginfig(25);
draw_upscrap(1)(1,((-272.95,-284.40)
 .. controls (-269.17,-281.16) and (-267.01,-278.28) .. (-263.59,-277.20)
 .. controls (-260.17,-276.12) and (-248.11,-273.24) .. (-240.37,-276.30)
 .. controls (-232.63,-279.36) and (-214.63,-285.48) .. (-208.87,-285.12)
 .. controls (-203.11,-284.76) and (-188.17,-278.82) .. (-184.57,-275.76)
 .. controls (-180.97,-272.70) and (-167.83,-266.22) .. (-165.67,-266.22)
 .. controls (-163.51,-266.22) and (-154.69,-260.10) .. (-151.63,-257.40)
 .. controls (-148.57,-254.70) and (-134.89,-249.48) .. (-132.91,-248.58)
 .. controls (-130.93,-247.68) and (-126.25,-243.54) .. (-124.45,-239.04)
 .. controls (-122.65,-234.54) and (-122.83,-233.28) .. (-118.15,-230.94)
 .. controls (-113.47,-228.60) and (-86.12,-214.02) .. (-80.90,-212.22)
 .. controls (-75.68,-210.42) and (-51.92,-203.40) .. (-44.36,-203.22)
 .. controls (-36.80,-203.04) and (-16.28,-198.90) .. (-7.82,-198.72)
 .. controls (0.64,-198.54) and (27.27,-194.94) .. (30.69,-195.12)
 .. controls (34.11,-195.30) and (51.57,-191.16) .. (54.63,-189.00)
 .. controls (57.69,-186.84) and (74.07,-174.06) .. (74.97,-170.64)
 .. controls (75.87,-167.22) and (74.25,-166.32) .. (73.89,-160.92)
 .. controls (73.53,-155.52) and (69.93,-155.34) .. (73.89,-149.04)
 .. controls (77.85,-142.75) and (90.81,-134.83) .. (95.85,-129.97)
 .. controls (100.89,-125.11) and (111.15,-113.23) .. (113.67,-109.27)
 .. controls (116.19,-105.31) and (130.05,-84.25) .. (131.31,-81.01)
 .. controls (132.57,-77.77) and (142.47,-48.07) .. (146.07,-42.67)
 .. controls (149.67,-37.27) and (162.45,-18.19) .. (166.77,-14.23)
 .. controls (171.09,-10.27) and (180.99,8.09) .. (181.71,14.21)
 .. controls (182.43,20.33) and (182.07,41.39) .. (181.71,45.35)
 .. controls (181.35,49.31) and (180.63,61.37) .. (185.67,68.93)
 .. controls (190.71,76.49) and (203.13,93.59) .. (209.97,96.83)
 .. controls (216.81,100.07) and (227.08,111.77) .. (233.38,116.27)
 .. controls (239.68,120.77) and (246.88,121.67) .. (249.04,120.94)
),
1,((249.04,120.94)
 .. controls (249.04,120.94) and (265.42,120.04) .. (269.20,118.42)
 .. controls (272.98,116.80) and (289.72,106.36) .. (293.50,105.28)
 .. controls (297.28,104.20) and (309.70,101.50) .. (315.82,103.30)
 .. controls (321.94,105.10) and (340.30,117.16) .. (342.28,119.50)
 .. controls (344.26,121.84) and (353.98,123.82) .. (358.84,124.00)
),
1,((358.84,124.00)
 .. controls (363.70,124.18) and (375.76,130.30) .. (379.18,133.36)
 .. controls (382.60,136.42) and (385.84,139.66) .. (390.70,144.88)
 .. controls (395.56,150.10) and (397.90,162.16) .. (405.10,162.16)
),
1,((388.54,329.55)
 .. controls (381.34,329.55) and (362.26,310.11) .. (362.26,310.11)
 .. controls (362.26,310.11) and (378.65,325.77) .. (351.46,298.59)
 .. controls (333.10,280.23) and (326.63,281.31) .. (326.63,281.31)
),
1,((326.63,281.31)
 .. controls (315.11,281.32) and (289.19,287.62) .. (283.97,291.94)
 .. controls (278.75,296.26) and (262.91,304.72) .. (259.67,309.22)
 .. controls (256.43,313.72) and (251.75,317.86) .. (251.75,317.86)
 .. controls (251.75,317.86) and (252.65,318.94) .. (254.99,323.44)
 .. controls (257.33,327.94) and (258.41,329.38) .. (258.41,329.38)
),
1,((252.65,337.66)
 .. controls (251.57,337.48) and (249.59,335.50) .. (246.53,333.70)
 .. controls (243.47,331.90) and (240.23,334.24) .. (238.79,336.94)
 .. controls (237.35,339.64) and (222.41,357.10) .. (220.79,358.90)
 .. controls (219.17,360.70) and (208.91,376.18) .. (206.57,378.88)
 .. controls (204.23,381.58) and (197.75,384.64) .. (197.75,385.54)
 .. controls (197.75,386.44) and (195.59,388.24) .. (198.65,390.94)
 .. controls (201.71,393.64) and (213.59,400.48) .. (213.95,404.08)
 .. controls (214.31,407.68) and (218.99,418.84) .. (219.53,422.26)
 .. controls (220.07,425.68) and (221.13,438.74) .. (207.83,434.86)
 .. controls (203.51,433.60) and (196.13,433.24) .. (194.51,431.62)
 .. controls (192.89,430.00) and (167.33,424.06) .. (162.65,424.06)
 .. controls (157.97,424.06) and (143.03,427.48) .. (140.15,428.56)
 .. controls (137.27,429.64) and (118.91,433.42) .. (114.05,435.40)
 .. controls (109.19,437.38) and (98.21,443.15) .. (93.71,444.41)
 .. controls (89.21,445.67) and (81.83,442.07) .. (75.35,442.97)
 .. controls (68.87,443.87) and (67.79,450.35) .. (61.49,447.83)
 .. controls (55.19,445.31) and (42.23,442.97) .. (36.83,441.34)
 .. controls (31.43,439.72) and (15.59,430.00) .. (12.35,426.76)
 .. controls (9.11,423.52) and (-4.57,411.64) .. (-6.55,409.30)
 .. controls (-8.53,406.96) and (-18.97,398.68) .. (-23.11,397.60)
 .. controls (-27.25,396.52) and (-59.65,386.26) .. (-64.69,382.84)
 .. controls (-69.73,379.42) and (-79.26,374.20) .. (-85.92,370.60)
 .. controls (-92.58,367.00) and (-104.10,364.66) .. (-109.14,361.24)
 .. controls (-114.18,357.82) and (-119.76,352.96) .. (-122.46,351.70)
 .. controls (-125.16,350.44) and (-129.84,351.52) .. (-130.20,348.64)
 .. controls (-130.56,345.76) and (-132.54,344.86) .. (-135.42,339.46)
 .. controls (-138.30,334.06) and (-141.18,327.58) .. (-142.62,324.34)
 .. controls (-144.06,321.10) and (-156.12,300.58) .. (-157.56,296.44)
 .. controls (-159.00,292.30) and (-165.84,276.11) .. (-168.72,270.53)
 .. controls (-171.60,264.95) and (-181.68,256.49) .. (-186.72,254.87)
 .. controls (-191.76,253.24) and (-205.98,254.50) .. (-209.76,254.68)
 .. controls (-213.54,254.86) and (-232.44,258.10) .. (-232.44,258.10)
),
1,((-254.76,170.45)
 .. controls (-253.14,171.53) and (-243.96,179.44) .. (-241.26,179.98)
 .. controls (-238.56,180.52) and (-232.98,187.00) .. (-227.76,182.86)
 .. controls (-222.54,178.72) and (-223.26,177.64) .. (-220.38,173.14)
 .. controls (-217.50,168.64) and (-213.54,163.06) .. (-212.10,158.56)
 .. controls (-210.66,154.06) and (-205.08,146.86) .. (-204.89,140.74)
 .. controls (-204.71,134.62) and (-203.81,122.03) .. (-206.87,114.65)
 .. controls (-209.93,107.27) and (-217.67,99.53) .. (-220.37,95.57)
 .. controls (-223.07,91.61) and (-232.44,82.61) .. (-234.96,79.91)
 .. controls (-237.48,77.21) and (-263.22,55.61) .. (-271.32,39.95)
 .. controls (-279.42,24.29) and (-287.16,14.57) .. (-288.96,10.07)
 .. controls (-290.76,5.57) and (-301.56,-12.78) .. (-307.50,-20.88)
 .. controls (-313.44,-28.98) and (-322.08,-41.94) .. (-325.86,-47.16)
 .. controls (-329.64,-52.38) and (-341.70,-66.60) .. (-343.50,-69.84)
 .. controls (-345.30,-73.08) and (-351.60,-75.06) .. (-346.56,-86.40)
 .. controls (-341.52,-97.74) and (-329.82,-110.70) .. (-326.76,-113.76)
 .. controls (-323.70,-116.82) and (-307.87,-130.50) .. (-304.45,-133.92)
 .. controls (-301.03,-137.34) and (-288.61,-147.96) .. (-285.55,-151.02)
 .. controls (-282.49,-154.08) and (-271.69,-167.94) .. (-268.81,-171.90)
 .. controls (-265.93,-175.86) and (-263.23,-189.54) .. (-268.81,-199.44)
 .. controls (-274.39,-209.34) and (-280.87,-217.08) .. (-283.75,-222.84)
 .. controls (-286.63,-228.60) and (-291.67,-240.12) .. (-292.57,-244.62)
 .. controls (-293.47,-249.12) and (-292.57,-252.36) .. (-292.57,-252.36)
),
1,((-292.57,-252.36)
 .. controls (-292.57,-252.36) and (-312.37,-274.14) .. (-324.61,-278.46)
),
1,reverse ((-272.95,-284.40)
 .. controls (-278.89,-287.10) and (-296.17,-304.02) .. (-296.17,-304.02)
));
draw_upscrap(0)(1,((253.18,139.30)
 .. controls (253.18,139.30) and (253.18,140.74) .. (253.18,144.88)
 .. controls (253.18,149.02) and (254.08,153.52) .. (253.36,160.00)
 .. controls (252.64,166.48) and (250.66,166.30) .. (249.22,166.84)
 .. controls (247.78,167.38) and (241.48,166.30) .. (237.88,166.84)
 .. controls (234.28,167.38) and (227.98,167.92) .. (224.38,169.72)
 .. controls (220.78,171.52) and (220.06,174.58) .. (218.08,177.46)
 .. controls (216.10,180.34) and (217.54,185.20) .. (217.90,187.72)
 .. controls (218.26,190.24) and (219.34,192.40) .. (220.06,191.86)
 .. controls (220.78,191.32) and (223.69,191.76) .. (227.62,190.06)
 .. controls (234.28,187.18) and (236.08,191.50) .. (237.16,192.22)
 .. controls (238.24,192.94) and (245.98,199.96) .. (250.30,202.30)
 .. controls (254.62,204.64) and (279.10,215.62) .. (284.68,217.42)
 .. controls (290.26,219.22) and (297.64,214.54) .. (303.40,213.46)
 .. controls (309.16,212.38) and (325.90,203.74) .. (330.22,202.48)
 .. controls (334.54,201.22) and (352.90,192.58) .. (356.14,190.78)
 .. controls (359.38,188.98) and (369.82,183.40) .. (373.06,181.24)
 .. controls (376.30,179.08) and (382.60,167.20) .. (382.42,164.68)
 .. controls (382.24,162.16) and (377.74,156.40) .. (373.78,152.98)
 .. controls (369.82,149.56) and (362.62,149.92) .. (359.02,146.86)
),
1,((359.02,146.86)
 .. controls (355.42,143.80) and (347.50,144.16) .. (344.44,144.16)
 .. controls (341.38,144.16) and (335.44,136.96) .. (332.56,134.62)
 .. controls (329.68,132.28) and (324.82,125.08) .. (323.38,122.92)
),
1,((323.38,122.92)
 .. controls (321.94,120.76) and (319.42,120.76) .. (317.26,120.40)
 .. controls (315.10,120.04) and (311.50,117.34) .. (307.90,117.70)
 .. controls (304.30,118.06) and (298.72,120.76) .. (295.48,123.10)
 .. controls (292.24,125.44) and (288.64,129.22) .. (286.84,132.28)
 .. controls (285.04,135.34) and (278.38,137.86) .. (274.78,139.84)
 .. controls (271.18,141.82) and (268.66,142.72) .. (260.20,140.74)
 .. controls (251.74,138.76) and (253.18,139.30) .. (253.18,139.30)
));
draw_upscrap(0)(1,((189.47,319.66)
 .. controls (190.91,321.64) and (194.15,322.90) .. (196.13,324.34)
 .. controls (198.11,325.78) and (199.37,332.08) .. (200.45,324.88)
 .. controls (201.53,317.68) and (203.33,313.36) .. (204.59,309.40)
 .. controls (205.85,305.44) and (208.55,297.34) .. (209.63,293.56)
 .. controls (210.71,289.78) and (216.11,272.14) .. (215.75,268.00)
 .. controls (215.39,263.86) and (215.75,252.70) .. (218.09,247.48)
 .. controls (220.43,242.26) and (222.59,241.18) .. (221.69,238.84)
 .. controls (220.79,236.50) and (216.11,228.76) .. (215.57,226.78)
 .. controls (215.03,224.80) and (204.41,218.50) .. (195.04,213.82)
 .. controls (185.68,209.14) and (183.34,204.82) .. (179.92,197.44)
 .. controls (176.50,190.06) and (172.54,177.47) .. (172.18,173.51)
 .. controls (171.82,169.55) and (168.04,150.47) .. (163.72,146.15)
 .. controls (159.40,141.83) and (150.58,127.61) .. (148.42,124.55)
 .. controls (146.26,121.49) and (143.38,107.63) .. (141.76,103.31)
 .. controls (140.14,98.99) and (120.52,68.21) .. (119.98,64.97)
 .. controls (119.44,61.73) and (103.05,30.41) .. (101.61,26.09)
 .. controls (100.17,21.77) and (89.01,-0.73) .. (89.01,-6.67)
 .. controls (89.01,-12.61) and (82.53,-22.69) .. (79.11,-26.83)
 .. controls (75.69,-30.97) and (57.51,-49.51) .. (53.19,-52.57)
 .. controls (48.87,-55.63) and (25.84,-70.39) .. (28.90,-82.99)
 .. controls (31.96,-95.59) and (41.85,-103.87) .. (42.21,-108.01)
 .. controls (42.57,-112.15) and (39.88,-121.69) .. (39.70,-124.39)
 .. controls (39.52,-127.09) and (31.78,-136.44) .. (15.76,-136.98)
 .. controls (-0.26,-137.52) and (-15.74,-136.80) .. (-20.96,-136.98)
 .. controls (-26.18,-137.16) and (-31.40,-142.20) .. (-37.88,-141.84)
 .. controls (-44.36,-141.48) and (-57.86,-137.52) .. (-62.72,-137.70)
 .. controls (-67.58,-137.88) and (-88.82,-136.44) .. (-95.84,-140.94)
 .. controls (-102.86,-145.44) and (-124.27,-157.15) .. (-129.49,-156.79)
 .. controls (-134.71,-156.43) and (-168.73,-155.17) .. (-175.75,-149.41)
 .. controls (-182.77,-143.65) and (-197.35,-134.47) .. (-203.47,-130.15)
 .. controls (-209.59,-125.83) and (-231.55,-106.39) .. (-234.25,-102.25)
 .. controls (-236.95,-98.11) and (-254.76,-83.17) .. (-259.80,-79.03)
 .. controls (-264.84,-74.89) and (-275.82,-70.74) .. (-271.32,-55.99)
 .. controls (-266.82,-41.23) and (-258.18,-22.87) .. (-254.58,-17.65)
 .. controls (-250.98,-12.43) and (-235.68,11.33) .. (-234.42,12.05)
 .. controls (-233.16,12.77) and (-218.40,30.95) .. (-215.52,33.47)
 .. controls (-212.64,35.99) and (-189.78,60.47) .. (-186.36,67.13)
 .. controls (-182.94,73.79) and (-170.69,96.28) .. (-170.69,100.60)
 .. controls (-170.69,104.92) and (-167.27,119.14) .. (-168.35,121.66)
 .. controls (-169.43,124.18) and (-171.23,130.84) .. (-171.41,136.97)
 .. controls (-171.60,143.09) and (-169.08,169.19) .. (-170.52,175.85)
 .. controls (-171.96,182.51) and (-175.02,199.25) .. (-173.58,204.29)
 .. controls (-172.14,209.33) and (-174.48,214.73) .. (-170.16,218.51)
 .. controls (-165.84,222.29) and (-158.28,220.85) .. (-155.05,227.33)
 .. controls (-151.81,233.81) and (-152.71,233.63) .. (-151.81,238.31)
 .. controls (-150.90,242.99) and (-141.37,248.75) .. (-133.99,252.35)
 .. controls (-126.61,255.95) and (-109.33,260.09) .. (-107.35,271.96)
 .. controls (-105.37,283.84) and (-100.33,294.46) .. (-98.35,299.50)
 .. controls (-96.37,304.54) and (-90.97,312.64) .. (-78.01,313.72)
 .. controls (-65.05,314.80) and (-66.13,318.58) .. (-62.17,323.08)
 .. controls (-58.21,327.58) and (-49.39,338.02) .. (-46.15,340.72)
 .. controls (-42.91,343.42) and (-35.89,344.50) .. (-31.93,345.22)
 .. controls (-27.97,345.94) and (-27.25,347.38) .. (-21.67,351.16)
 .. controls (-16.09,354.94) and (-4.57,356.92) .. (0.83,355.48)
 .. controls (6.23,354.04) and (20.09,354.04) .. (23.87,356.56)
 .. controls (27.65,359.08) and (28.01,359.98) .. (38.27,362.50)
 .. controls (48.53,365.02) and (61.49,366.64) .. (64.91,372.04)
 .. controls (68.33,377.44) and (69.59,388.43) .. (75.17,392.21)
 .. controls (80.75,395.98) and (92.63,401.20) .. (96.77,395.62)
 .. controls (100.91,390.04) and (101.63,389.68) .. (104.15,387.52)
 .. controls (106.67,385.36) and (109.37,383.92) .. (114.41,385.36)
 .. controls (119.45,386.80) and (128.09,388.24) .. (130.25,384.64)
 .. controls (132.41,381.04) and (129.17,380.50) .. (131.51,375.46)
 .. controls (133.85,370.42) and (135.65,370.78) .. (136.73,367.00)
 .. controls (137.81,363.22) and (134.57,358.54) .. (134.75,354.58)
 .. controls (134.93,350.62) and (137.27,344.86) .. (139.43,343.42)
 .. controls (141.59,341.98) and (150.77,341.08) .. (154.01,344.68)
 .. controls (157.25,348.28) and (161.93,354.22) .. (166.07,354.94)
 .. controls (170.21,355.66) and (172.73,360.34) .. (180.47,357.82)
 .. controls (188.21,355.30) and (190.01,352.96) .. (190.91,350.08)
 .. controls (191.81,347.20) and (195.77,343.24) .. (193.61,340.00)
 .. controls (191.45,336.76) and (184.61,328.30) .. (184.25,327.22)
));
draw_upscrap(0)(1,((120.87,10.25)
 .. controls (119.43,7.91) and (119.79,8.63) .. (119.07,7.73)
 .. controls (118.35,6.83) and (117.81,5.21) .. (111.51,-2.17)
 .. controls (105.21,-9.55) and (107.73,-1.63) .. (107.73,-1.63)
 .. controls (107.73,-1.63) and (110.25,5.93) .. (111.69,8.81)
 .. controls (113.13,11.69) and (122.13,29.15) .. (123.03,33.65)
 .. controls (123.93,38.15) and (128.07,44.09) .. (134.37,50.93)
 .. controls (140.67,57.77) and (141.39,50.39) .. (140.85,48.23)
 .. controls (140.31,46.07) and (135.45,35.27) .. (133.65,31.13)
 .. controls (131.85,26.99) and (122.31,12.59) .. cycle
));
draw_downscrap;
endfig;
beginfig(26);
drawoptions();
p_gradient((-212.64,213.29),83.4,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-292.57,-252.36)
 .. controls (-292.57,-252.36) and (-312.37,-274.14) .. (-324.61,-278.46)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((326.63,281.31)
 .. controls (315.11,281.32) and (289.19,287.62) .. (283.97,291.94)
 .. controls (278.75,296.26) and (262.91,304.72) .. (259.67,309.22)
 .. controls (256.43,313.72) and (251.75,317.86) .. (251.75,317.86)
 .. controls (251.75,317.86) and (252.65,318.94) .. (254.99,323.44)
 .. controls (257.33,327.94) and (258.41,329.38) .. (258.41,329.38)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((252.65,337.66)
 .. controls (251.57,337.48) and (249.59,335.50) .. (246.53,333.70)
 .. controls (243.47,331.90) and (240.23,334.24) .. (238.79,336.94)
 .. controls (237.35,339.64) and (222.41,357.10) .. (220.79,358.90)
 .. controls (219.17,360.70) and (208.91,376.18) .. (206.57,378.88)
 .. controls (204.23,381.58) and (197.75,384.64) .. (197.75,385.54)
 .. controls (197.75,386.44) and (195.59,388.24) .. (198.65,390.94)
 .. controls (201.71,393.64) and (213.59,400.48) .. (213.95,404.08)
 .. controls (214.31,407.68) and (218.99,418.84) .. (219.53,422.26)
 .. controls (220.07,425.68) and (221.13,438.74) .. (207.83,434.86)
 .. controls (203.51,433.60) and (196.13,433.24) .. (194.51,431.62)
 .. controls (192.89,430.00) and (167.33,424.06) .. (162.65,424.06)
 .. controls (157.97,424.06) and (143.03,427.48) .. (140.15,428.56)
 .. controls (137.27,429.64) and (118.91,433.42) .. (114.05,435.40)
 .. controls (109.19,437.38) and (98.21,443.15) .. (93.71,444.41)
 .. controls (89.21,445.67) and (81.83,442.07) .. (75.35,442.97)
 .. controls (68.87,443.87) and (67.79,450.35) .. (61.49,447.83)
 .. controls (55.19,445.31) and (42.23,442.97) .. (36.83,441.34)
 .. controls (31.43,439.72) and (15.59,430.00) .. (12.35,426.76)
 .. controls (9.11,423.52) and (-4.57,411.64) .. (-6.55,409.30)
 .. controls (-8.53,406.96) and (-18.97,398.68) .. (-23.11,397.60)
 .. controls (-27.25,396.52) and (-59.65,386.26) .. (-64.69,382.84)
 .. controls (-69.73,379.42) and (-79.26,374.20) .. (-85.92,370.60)
 .. controls (-92.58,367.00) and (-104.10,364.66) .. (-109.14,361.24)
 .. controls (-114.18,357.82) and (-119.76,352.96) .. (-122.46,351.70)
 .. controls (-125.16,350.44) and (-129.84,351.52) .. (-130.20,348.64)
 .. controls (-130.56,345.76) and (-132.54,344.86) .. (-135.42,339.46)
 .. controls (-138.30,334.06) and (-141.18,327.58) .. (-142.62,324.34)
 .. controls (-144.06,321.10) and (-156.12,300.58) .. (-157.56,296.44)
 .. controls (-159.00,292.30) and (-165.84,276.11) .. (-168.72,270.53)
 .. controls (-171.60,264.95) and (-181.68,256.49) .. (-186.72,254.87)
 .. controls (-191.76,253.24) and (-205.98,254.50) .. (-209.76,254.68)
 .. controls (-213.54,254.86) and (-232.44,258.10) .. (-232.44,258.10)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-254.76,170.45)
 .. controls (-253.14,171.53) and (-243.96,179.44) .. (-241.26,179.98)
 .. controls (-238.56,180.52) and (-232.98,187.00) .. (-227.76,182.86)
 .. controls (-222.54,178.72) and (-223.26,177.64) .. (-220.38,173.14)
 .. controls (-217.50,168.64) and (-213.54,163.06) .. (-212.10,158.56)
 .. controls (-210.66,154.06) and (-205.08,146.86) .. (-204.89,140.74)
 .. controls (-204.71,134.62) and (-203.81,122.03) .. (-206.87,114.65)
 .. controls (-209.93,107.27) and (-217.67,99.53) .. (-220.37,95.57)
 .. controls (-223.07,91.61) and (-232.44,82.61) .. (-234.96,79.91)
 .. controls (-237.48,77.21) and (-263.22,55.61) .. (-271.32,39.95)
 .. controls (-279.42,24.29) and (-287.16,14.57) .. (-288.96,10.07)
 .. controls (-290.76,5.57) and (-301.56,-12.78) .. (-307.50,-20.88)
 .. controls (-313.44,-28.98) and (-322.08,-41.94) .. (-325.86,-47.16)
 .. controls (-329.64,-52.38) and (-341.70,-66.60) .. (-343.50,-69.84)
 .. controls (-345.30,-73.08) and (-351.60,-75.06) .. (-346.56,-86.40)
 .. controls (-341.52,-97.74) and (-329.82,-110.70) .. (-326.76,-113.76)
 .. controls (-323.70,-116.82) and (-307.87,-130.50) .. (-304.45,-133.92)
 .. controls (-301.03,-137.34) and (-288.61,-147.96) .. (-285.55,-151.02)
 .. controls (-282.49,-154.08) and (-271.69,-167.94) .. (-268.81,-171.90)
 .. controls (-265.93,-175.86) and (-263.23,-189.54) .. (-268.81,-199.44)
 .. controls (-274.39,-209.34) and (-280.87,-217.08) .. (-283.75,-222.84)
 .. controls (-286.63,-228.60) and (-291.67,-240.12) .. (-292.57,-244.62)
 .. controls (-293.47,-249.12) and (-292.57,-252.36) .. (-292.57,-252.36)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((358.84,124.00)
 .. controls (363.70,124.18) and (375.76,130.30) .. (379.18,133.36)
 .. controls (382.60,136.42) and (385.84,139.66) .. (390.70,144.88)
 .. controls (395.56,150.10) and (397.90,162.16) .. (405.10,162.16)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((249.04,120.94)
 .. controls (249.04,120.94) and (265.42,120.04) .. (269.20,118.42)
 .. controls (272.98,116.80) and (289.72,106.36) .. (293.50,105.28)
 .. controls (297.28,104.20) and (309.70,101.50) .. (315.82,103.30)
 .. controls (321.94,105.10) and (340.30,117.16) .. (342.28,119.50)
 .. controls (344.26,121.84) and (353.98,123.82) .. (358.84,124.00)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-272.95,-284.40)
 .. controls (-269.17,-281.16) and (-267.01,-278.28) .. (-263.59,-277.20)
 .. controls (-260.17,-276.12) and (-248.11,-273.24) .. (-240.37,-276.30)
 .. controls (-232.63,-279.36) and (-214.63,-285.48) .. (-208.87,-285.12)
 .. controls (-203.11,-284.76) and (-188.17,-278.82) .. (-184.57,-275.76)
 .. controls (-180.97,-272.70) and (-167.83,-266.22) .. (-165.67,-266.22)
 .. controls (-163.51,-266.22) and (-154.69,-260.10) .. (-151.63,-257.40)
 .. controls (-148.57,-254.70) and (-134.89,-249.48) .. (-132.91,-248.58)
 .. controls (-130.93,-247.68) and (-126.25,-243.54) .. (-124.45,-239.04)
 .. controls (-122.65,-234.54) and (-122.83,-233.28) .. (-118.15,-230.94)
 .. controls (-113.47,-228.60) and (-86.12,-214.02) .. (-80.90,-212.22)
 .. controls (-75.68,-210.42) and (-51.92,-203.40) .. (-44.36,-203.22)
 .. controls (-36.80,-203.04) and (-16.28,-198.90) .. (-7.82,-198.72)
 .. controls (0.64,-198.54) and (27.27,-194.94) .. (30.69,-195.12)
 .. controls (34.11,-195.30) and (51.57,-191.16) .. (54.63,-189.00)
 .. controls (57.69,-186.84) and (74.07,-174.06) .. (74.97,-170.64)
 .. controls (75.87,-167.22) and (74.25,-166.32) .. (73.89,-160.92)
 .. controls (73.53,-155.52) and (69.93,-155.34) .. (73.89,-149.04)
 .. controls (77.85,-142.75) and (90.81,-134.83) .. (95.85,-129.97)
 .. controls (100.89,-125.11) and (111.15,-113.23) .. (113.67,-109.27)
 .. controls (116.19,-105.31) and (130.05,-84.25) .. (131.31,-81.01)
 .. controls (132.57,-77.77) and (142.47,-48.07) .. (146.07,-42.67)
 .. controls (149.67,-37.27) and (162.45,-18.19) .. (166.77,-14.23)
 .. controls (171.09,-10.27) and (180.99,8.09) .. (181.71,14.21)
 .. controls (182.43,20.33) and (182.07,41.39) .. (181.71,45.35)
 .. controls (181.35,49.31) and (180.63,61.37) .. (185.67,68.93)
 .. controls (190.71,76.49) and (203.13,93.59) .. (209.97,96.83)
 .. controls (216.81,100.07) and (227.08,111.77) .. (233.38,116.27)
 .. controls (239.68,120.77) and (246.88,121.67) .. (249.04,120.94)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-272.95,-284.40)
 .. controls (-278.89,-287.10) and (-296.17,-304.02) .. (-296.17,-304.02)
));
drawoptions();
p_waterflow_permanent((400.06,174.04),144.7,1.00,(0,0));
drawoptions();
p_rimstonepool((-338.64,-87.66),122.9,1.00,(0,0));
drawoptions();
p_rimstonepool((-324.60,-100.98),126.4,1.00,(0,0));
drawoptions();
p_rimstonepool((-333.96,-79.38),101.8,1.00,(0,0));
drawoptions();
p_rimstonepool((-325.68,-89.46),136.6,1.00,(0,0));
drawoptions();
p_rimstonepool((-314.16,-93.06),140.5,1.00,(0,0));
drawoptions();
p_waterflow_permanent((74.61,-123.67),137.7,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((388.54,329.55)
 .. controls (381.34,329.55) and (362.26,310.11) .. (362.26,310.11)
 .. controls (362.26,310.11) and (378.65,325.77) .. (351.46,298.59)
 .. controls (333.10,280.23) and (326.63,281.31) .. (326.63,281.31)
));
drawoptions();
p_waterflow_permanent((75.33,-69.67),144.9,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((323.38,122.92)
 .. controls (321.94,120.76) and (319.42,120.76) .. (317.26,120.40)
 .. controls (315.10,120.04) and (311.50,117.34) .. (307.90,117.70)
 .. controls (304.30,118.06) and (298.72,120.76) .. (295.48,123.10)
 .. controls (292.24,125.44) and (288.64,129.22) .. (286.84,132.28)
 .. controls (285.04,135.34) and (278.38,137.86) .. (274.78,139.84)
 .. controls (271.18,141.82) and (268.66,142.72) .. (260.20,140.74)
 .. controls (251.74,138.76) and (253.18,139.30) .. (253.18,139.30)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((253.18,139.30)
 .. controls (253.18,139.30) and (253.18,140.74) .. (253.18,144.88)
 .. controls (253.18,149.02) and (254.08,153.52) .. (253.36,160.00)
 .. controls (252.64,166.48) and (250.66,166.30) .. (249.22,166.84)
 .. controls (247.78,167.38) and (241.48,166.30) .. (237.88,166.84)
 .. controls (234.28,167.38) and (227.98,167.92) .. (224.38,169.72)
 .. controls (220.78,171.52) and (220.06,174.58) .. (218.08,177.46)
 .. controls (216.10,180.34) and (217.54,185.20) .. (217.90,187.72)
 .. controls (218.26,190.24) and (219.34,192.40) .. (220.06,191.86)
 .. controls (220.78,191.32) and (223.69,191.76) .. (227.62,190.06)
 .. controls (234.28,187.18) and (236.08,191.50) .. (237.16,192.22)
 .. controls (238.24,192.94) and (245.98,199.96) .. (250.30,202.30)
 .. controls (254.62,204.64) and (279.10,215.62) .. (284.68,217.42)
 .. controls (290.26,219.22) and (297.64,214.54) .. (303.40,213.46)
 .. controls (309.16,212.38) and (325.90,203.74) .. (330.22,202.48)
 .. controls (334.54,201.22) and (352.90,192.58) .. (356.14,190.78)
 .. controls (359.38,188.98) and (369.82,183.40) .. (373.06,181.24)
 .. controls (376.30,179.08) and (382.60,167.20) .. (382.42,164.68)
 .. controls (382.24,162.16) and (377.74,156.40) .. (373.78,152.98)
 .. controls (369.82,149.56) and (362.62,149.92) .. (359.02,146.86)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((359.02,146.86)
 .. controls (355.42,143.80) and (347.50,144.16) .. (344.44,144.16)
 .. controls (341.38,144.16) and (335.44,136.96) .. (332.56,134.62)
 .. controls (329.68,132.28) and (324.82,125.08) .. (323.38,122.92)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((189.47,319.66)
 .. controls (190.91,321.64) and (194.15,322.90) .. (196.13,324.34)
 .. controls (198.11,325.78) and (199.37,332.08) .. (200.45,324.88)
 .. controls (201.53,317.68) and (203.33,313.36) .. (204.59,309.40)
 .. controls (205.85,305.44) and (208.55,297.34) .. (209.63,293.56)
 .. controls (210.71,289.78) and (216.11,272.14) .. (215.75,268.00)
 .. controls (215.39,263.86) and (215.75,252.70) .. (218.09,247.48)
 .. controls (220.43,242.26) and (222.59,241.18) .. (221.69,238.84)
 .. controls (220.79,236.50) and (216.11,228.76) .. (215.57,226.78)
 .. controls (215.03,224.80) and (204.41,218.50) .. (195.04,213.82)
 .. controls (185.68,209.14) and (183.34,204.82) .. (179.92,197.44)
 .. controls (176.50,190.06) and (172.54,177.47) .. (172.18,173.51)
 .. controls (171.82,169.55) and (168.04,150.47) .. (163.72,146.15)
 .. controls (159.40,141.83) and (150.58,127.61) .. (148.42,124.55)
 .. controls (146.26,121.49) and (143.38,107.63) .. (141.76,103.31)
 .. controls (140.14,98.99) and (120.52,68.21) .. (119.98,64.97)
 .. controls (119.44,61.73) and (103.05,30.41) .. (101.61,26.09)
 .. controls (100.17,21.77) and (89.01,-0.73) .. (89.01,-6.67)
 .. controls (89.01,-12.61) and (82.53,-22.69) .. (79.11,-26.83)
 .. controls (75.69,-30.97) and (57.51,-49.51) .. (53.19,-52.57)
 .. controls (48.87,-55.63) and (25.84,-70.39) .. (28.90,-82.99)
 .. controls (31.96,-95.59) and (41.85,-103.87) .. (42.21,-108.01)
 .. controls (42.57,-112.15) and (39.88,-121.69) .. (39.70,-124.39)
 .. controls (39.52,-127.09) and (31.78,-136.44) .. (15.76,-136.98)
 .. controls (-0.26,-137.52) and (-15.74,-136.80) .. (-20.96,-136.98)
 .. controls (-26.18,-137.16) and (-31.40,-142.20) .. (-37.88,-141.84)
 .. controls (-44.36,-141.48) and (-57.86,-137.52) .. (-62.72,-137.70)
 .. controls (-67.58,-137.88) and (-88.82,-136.44) .. (-95.84,-140.94)
 .. controls (-102.86,-145.44) and (-124.27,-157.15) .. (-129.49,-156.79)
 .. controls (-134.71,-156.43) and (-168.73,-155.17) .. (-175.75,-149.41)
 .. controls (-182.77,-143.65) and (-197.35,-134.47) .. (-203.47,-130.15)
 .. controls (-209.59,-125.83) and (-231.55,-106.39) .. (-234.25,-102.25)
 .. controls (-236.95,-98.11) and (-254.76,-83.17) .. (-259.80,-79.03)
 .. controls (-264.84,-74.89) and (-275.82,-70.74) .. (-271.32,-55.99)
 .. controls (-266.82,-41.23) and (-258.18,-22.87) .. (-254.58,-17.65)
 .. controls (-250.98,-12.43) and (-235.68,11.33) .. (-234.42,12.05)
 .. controls (-233.16,12.77) and (-218.40,30.95) .. (-215.52,33.47)
 .. controls (-212.64,35.99) and (-189.78,60.47) .. (-186.36,67.13)
 .. controls (-182.94,73.79) and (-170.69,96.28) .. (-170.69,100.60)
 .. controls (-170.69,104.92) and (-167.27,119.14) .. (-168.35,121.66)
 .. controls (-169.43,124.18) and (-171.23,130.84) .. (-171.41,136.97)
 .. controls (-171.60,143.09) and (-169.08,169.19) .. (-170.52,175.85)
 .. controls (-171.96,182.51) and (-175.02,199.25) .. (-173.58,204.29)
 .. controls (-172.14,209.33) and (-174.48,214.73) .. (-170.16,218.51)
 .. controls (-165.84,222.29) and (-158.28,220.85) .. (-155.05,227.33)
 .. controls (-151.81,233.81) and (-152.71,233.63) .. (-151.81,238.31)
 .. controls (-150.90,242.99) and (-141.37,248.75) .. (-133.99,252.35)
 .. controls (-126.61,255.95) and (-109.33,260.09) .. (-107.35,271.96)
 .. controls (-105.37,283.84) and (-100.33,294.46) .. (-98.35,299.50)
 .. controls (-96.37,304.54) and (-90.97,312.64) .. (-78.01,313.72)
 .. controls (-65.05,314.80) and (-66.13,318.58) .. (-62.17,323.08)
 .. controls (-58.21,327.58) and (-49.39,338.02) .. (-46.15,340.72)
 .. controls (-42.91,343.42) and (-35.89,344.50) .. (-31.93,345.22)
 .. controls (-27.97,345.94) and (-27.25,347.38) .. (-21.67,351.16)
 .. controls (-16.09,354.94) and (-4.57,356.92) .. (0.83,355.48)
 .. controls (6.23,354.04) and (20.09,354.04) .. (23.87,356.56)
 .. controls (27.65,359.08) and (28.01,359.98) .. (38.27,362.50)
 .. controls (48.53,365.02) and (61.49,366.64) .. (64.91,372.04)
 .. controls (68.33,377.44) and (69.59,388.43) .. (75.17,392.21)
 .. controls (80.75,395.98) and (92.63,401.20) .. (96.77,395.62)
 .. controls (100.91,390.04) and (101.63,389.68) .. (104.15,387.52)
 .. controls (106.67,385.36) and (109.37,383.92) .. (114.41,385.36)
 .. controls (119.45,386.80) and (128.09,388.24) .. (130.25,384.64)
 .. controls (132.41,381.04) and (129.17,380.50) .. (131.51,375.46)
 .. controls (133.85,370.42) and (135.65,370.78) .. (136.73,367.00)
 .. controls (137.81,363.22) and (134.57,358.54) .. (134.75,354.58)
 .. controls (134.93,350.62) and (137.27,344.86) .. (139.43,343.42)
 .. controls (141.59,341.98) and (150.77,341.08) .. (154.01,344.68)
 .. controls (157.25,348.28) and (161.93,354.22) .. (166.07,354.94)
 .. controls (170.21,355.66) and (172.73,360.34) .. (180.47,357.82)
 .. controls (188.21,355.30) and (190.01,352.96) .. (190.91,350.08)
 .. controls (191.81,347.20) and (195.77,343.24) .. (193.61,340.00)
 .. controls (191.45,336.76) and (184.61,328.30) .. (184.25,327.22)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((120.87,10.25)
 .. controls (119.43,7.91) and (119.79,8.63) .. (119.07,7.73)
 .. controls (118.35,6.83) and (117.81,5.21) .. (111.51,-2.17)
 .. controls (105.21,-9.55) and (107.73,-1.63) .. (107.73,-1.63)
 .. controls (107.73,-1.63) and (110.25,5.93) .. (111.69,8.81)
 .. controls (113.13,11.69) and (122.13,29.15) .. (123.03,33.65)
 .. controls (123.93,38.15) and (128.07,44.09) .. (134.37,50.93)
 .. controls (140.67,57.77) and (141.39,50.39) .. (140.85,48.23)
 .. controls (140.31,46.07) and (135.45,35.27) .. (133.65,31.13)
 .. controls (131.85,26.99) and (122.31,12.59) .. cycle
));
endfig;
beginfig(27);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char116 \char116 \mainfont{} etex,(271.19,345.40),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char116 \char116 \mainfont{} etex,(174.35,313.00),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char116 \char116 \mainfont{} etex,(-264.84,222.64),0.0,0);
endfig;
background:=(0.56500,1.00000,0.25000);
def_transparent_rgb(tr_bg, 0.56500, 1.00000, 0.25000);
current_scrap := "Romeo_1.12SP1@Romeo_1_12.romeo";
ATTR__scrap := "Romeo_1.12SP1";
beginfig(28);
ATTR__survey := "Romeo_1_12.romeo";
current_src := "Romeo_1_12.th2 [303]";
string area_border[];
area_border[1] := "l43-3300-5252";
drawoptions();
a_pebbles(buildcycle(((34.09,215.46)
 .. controls (34.09,215.46) and (142.16,176.71) .. (166.47,81.40)
 .. controls (190.78,-13.88) and (128.16,-66.43) .. (128.16,-66.43)
 -- (-146.14,-273.81)
 .. controls (-146.14,-273.81) and (-407.69,-280.64) .. (-373.02,-154.41)
 .. controls (-338.38,-28.32) and (34.09,215.46) .. cycle
)));
current_src := "Romeo_1_12.th2 [253]";
string area_border[];
area_border[1] := "l68-5120-5850";
drawoptions();
a_pebbles(buildcycle(((315.59,301.11)
 -- (310.26,282.14)
 -- (350.59,268.47)
 -- (358.46,286.76)
 -- cycle
)));
current_src := "Romeo_1_12.th2 [198]";
string area_border[];
area_border[1] := "l18-1484-1580";
drawoptions();
a_water(buildcycle(((-368.93,-426.22)
 .. controls (-379.01,-416.86) and (-371.81,-426.94) .. (-378.29,-424.79)
 .. controls (-384.78,-422.63) and (-390.54,-428.40) .. (-410.73,-437.08)
 .. controls (-430.91,-445.75) and (-422.99,-460.16) .. (-428.04,-472.41)
 .. controls (-433.10,-484.67) and (-445.35,-499.10) .. (-449.69,-510.63)
 .. controls (-454.02,-522.17) and (-457.62,-527.22) .. (-437.46,-544.50)
 .. controls (-417.31,-561.79) and (-412.98,-556.74) .. (-405.78,-553.85)
 .. controls (-398.57,-550.96) and (-384.89,-552.40) .. (-367.60,-557.43)
 .. controls (-350.32,-562.47) and (-329.43,-551.64) .. (-320.77,-542.27)
 .. controls (-312.12,-532.89) and (-317.14,-506.22) .. (-320.73,-493.96)
 .. controls (-324.32,-481.71) and (-333.67,-471.62) .. (-342.30,-454.32)
 .. controls (-350.93,-437.02) and (-358.85,-435.58) .. cycle
)));
current_src := "Romeo_1_12.th2 [180]";
string area_border[];
area_border[1] := "l22-1600-2104";
area_border[2] := "l18-1484-1580";
drawoptions();
a_blocks(buildcycle(((-363.89,-430.54)
 .. controls (-363.89,-430.54) and (-371.07,-405.31) .. (-361.70,-398.81)
 .. controls (-352.32,-392.31) and (-342.94,-380.04) .. (-325.65,-377.14)
 .. controls (-308.36,-374.24) and (-290.34,-372.06) .. (-281.70,-374.93)
 .. controls (-273.06,-377.81) and (-262.26,-379.97) .. (-258.67,-389.35)
 .. controls (-255.08,-398.72) and (-250.78,-418.20) .. (-248.63,-429.01)
 .. controls (-246.49,-439.83) and (-241.47,-462.91) .. (-248.68,-473.01)
 .. controls (-255.90,-483.11) and (-278.24,-498.99) .. (-288.32,-497.55)
 .. controls (-298.40,-496.11) and (-320.02,-501.17) .. (-320.02,-501.17)
),
((-368.93,-426.22)
 .. controls (-379.01,-416.86) and (-371.81,-426.94) .. (-378.29,-424.79)
 .. controls (-384.78,-422.63) and (-390.54,-428.40) .. (-410.73,-437.08)
 .. controls (-430.91,-445.75) and (-422.99,-460.16) .. (-428.04,-472.41)
 .. controls (-433.10,-484.67) and (-445.35,-499.10) .. (-449.69,-510.63)
 .. controls (-454.02,-522.17) and (-457.62,-527.22) .. (-437.46,-544.50)
 .. controls (-417.31,-561.79) and (-412.98,-556.74) .. (-405.78,-553.85)
 .. controls (-398.57,-550.96) and (-384.89,-552.40) .. (-367.60,-557.43)
 .. controls (-350.32,-562.47) and (-329.43,-551.64) .. (-320.77,-542.27)
 .. controls (-312.12,-532.89) and (-317.14,-506.22) .. (-320.73,-493.96)
 .. controls (-324.32,-481.71) and (-333.67,-471.62) .. (-342.30,-454.32)
 .. controls (-350.93,-437.02) and (-358.85,-435.58) .. cycle
)));
current_src := "Romeo_1_12.th2 [63]";
string area_border[];
area_border[1] := "l38-5101-5602";
drawoptions();
a_water(buildcycle(((312.49,259.75)
 .. controls (310.68,257.95) and (305.81,254.15) .. (305.09,251.45)
 .. controls (304.37,248.75) and (304.20,246.23) .. (306.54,245.15)
 .. controls (308.88,244.07) and (311.22,241.37) .. (313.92,243.90)
 .. controls (316.63,246.44) and (318.80,247.89) .. (319.70,251.32)
 .. controls (320.61,254.75) and (320.79,256.73) .. (319.89,258.17)
 .. controls (318.99,259.60) and (318.08,261.76) .. (316.10,260.85)
 .. controls (314.11,259.94) and (314.29,261.56) .. cycle
)));
current_src := "Romeo_1_12.th2 [59]";
string area_border[];
area_border[1] := "l37-5242-5867";
drawoptions();
a_water(buildcycle(((344.09,304.45)
 .. controls (342.83,305.35) and (342.29,304.62) .. (340.48,305.33)
 .. controls (338.68,306.05) and (337.95,305.68) .. (335.96,304.05)
 .. controls (333.98,302.42) and (334.34,298.83) .. (335.79,296.67)
 .. controls (337.23,294.52) and (339.93,295.24) .. (341.37,295.96)
 .. controls (342.82,296.69) and (344.44,298.49) .. (345.34,299.94)
 .. controls (346.25,301.39) and (345.35,303.55) .. cycle
)));
current_src := "Romeo_1_12.th2 [55]";
string area_border[];
area_border[1] := "l34-5365-6397";
drawoptions();
a_water(buildcycle(((350.71,401.90)
 .. controls (346.89,401.48) and (347.98,400.78) .. (346.71,400.58)
 .. controls (345.43,400.38) and (343.44,399.27) .. (340.90,397.26)
 .. controls (338.37,395.26) and (337.65,392.39) .. (336.58,390.06)
 .. controls (335.50,387.73) and (336.60,385.60) .. (337.16,383.64)
 .. controls (337.71,381.69) and (340.06,380.99) .. (342.61,378.15)
 .. controls (345.16,375.32) and (351.48,374.99) .. (355.63,375.00)
 .. controls (359.78,375.02) and (366.24,381.12) .. (367.15,384.73)
 .. controls (368.07,388.35) and (368.44,391.26) .. (367.94,395.63)
 .. controls (367.43,400.00) and (365.81,400.72) .. (362.55,402.48)
 .. controls (359.28,404.24) and (354.53,402.33) .. cycle
)));
ATTR__id := "l43-3300-5252";
ATTR__height := -1;
drawoptions();
l_border_invisible(((34.09,215.46)
 .. controls (34.09,215.46) and (142.16,176.71) .. (166.47,81.40)
 .. controls (190.78,-13.88) and (128.16,-66.43) .. (128.16,-66.43)
 -- (-146.14,-273.81)
 .. controls (-146.14,-273.81) and (-407.69,-280.64) .. (-373.02,-154.41)
 .. controls (-338.38,-28.32) and (34.09,215.46) .. cycle
));
ATTR__id := "l68-5120-5850";
ATTR__height := -1;
drawoptions();
l_border_invisible(((315.59,301.11)
 -- (310.26,282.14)
 -- (350.59,268.47)
 -- (358.46,286.76)
 -- cycle
));
ATTR__id := "l18-1484-1580";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-368.93,-426.22)
 .. controls (-379.01,-416.86) and (-371.81,-426.94) .. (-378.29,-424.79)
 .. controls (-384.78,-422.63) and (-390.54,-428.40) .. (-410.73,-437.08)
 .. controls (-430.91,-445.75) and (-422.99,-460.16) .. (-428.04,-472.41)
 .. controls (-433.10,-484.67) and (-445.35,-499.10) .. (-449.69,-510.63)
 .. controls (-454.02,-522.17) and (-457.62,-527.22) .. (-437.46,-544.50)
 .. controls (-417.31,-561.79) and (-412.98,-556.74) .. (-405.78,-553.85)
 .. controls (-398.57,-550.96) and (-384.89,-552.40) .. (-367.60,-557.43)
 .. controls (-350.32,-562.47) and (-329.43,-551.64) .. (-320.77,-542.27)
 .. controls (-312.12,-532.89) and (-317.14,-506.22) .. (-320.73,-493.96)
 .. controls (-324.32,-481.71) and (-333.67,-471.62) .. (-342.30,-454.32)
 .. controls (-350.93,-437.02) and (-358.85,-435.58) .. cycle
));
ATTR__id := "l22-1600-2104";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-363.89,-430.54)
 .. controls (-363.89,-430.54) and (-371.07,-405.31) .. (-361.70,-398.81)
 .. controls (-352.32,-392.31) and (-342.94,-380.04) .. (-325.65,-377.14)
 .. controls (-308.36,-374.24) and (-290.34,-372.06) .. (-281.70,-374.93)
 .. controls (-273.06,-377.81) and (-262.26,-379.97) .. (-258.67,-389.35)
 .. controls (-255.08,-398.72) and (-250.78,-418.20) .. (-248.63,-429.01)
 .. controls (-246.49,-439.83) and (-241.47,-462.91) .. (-248.68,-473.01)
 .. controls (-255.90,-483.11) and (-278.24,-498.99) .. (-288.32,-497.55)
 .. controls (-298.40,-496.11) and (-320.02,-501.17) .. (-320.02,-501.17)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((344.95,430.24)
 .. controls (344.95,430.24) and (346.63,426.92) .. (349.54,430.74)
 .. controls (352.43,434.54) and (356.03,439.04) .. (355.80,441.13)
 .. controls (355.58,443.21) and (356.43,445.66) .. (354.38,446.81)
 .. controls (352.33,447.96) and (347.81,452.32) .. (347.81,452.32)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((362.19,505.26)
 .. controls (362.19,505.26) and (366.70,503.12) .. (367.89,500.22)
 .. controls (369.08,497.33) and (370.94,495.44) .. (370.75,492.27)
 .. controls (370.55,489.12) and (370.84,486.95) .. (368.94,485.98)
 .. controls (367.02,485.01) and (365.08,484.53) .. (365.08,484.53)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((357.51,489.29)
 .. controls (357.51,489.29) and (358.88,486.76) .. (361.25,485.90)
 .. controls (363.62,485.04) and (364.34,484.87) .. (365.89,482.69)
 .. controls (367.44,480.52) and (369.43,476.86) .. (369.74,474.54)
 .. controls (370.05,472.23) and (368.51,470.73) .. (367.87,469.24)
 .. controls (367.22,467.74) and (366.25,465.56) .. (364.64,465.04)
 .. controls (363.03,464.52) and (362.35,463.51) .. (362.35,463.51)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((359.78,472.03)
 .. controls (360.77,470.20) and (362.14,468.03) .. (362.22,466.36)
 .. controls (362.30,464.68) and (361.64,463.16) .. (361.92,461.15)
 .. controls (362.19,459.13) and (362.23,457.95) .. (360.28,456.55)
 .. controls (358.33,455.15) and (356.50,455.11) .. (354.51,454.38)
 .. controls (352.53,453.64) and (347.77,453.53) .. (347.77,453.53)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((370.80,487.78)
 .. controls (370.80,487.78) and (371.88,487.60) .. (372.73,485.10)
 .. controls (373.58,482.61) and (373.92,479.80) .. (373.87,477.66)
 .. controls (373.81,475.51) and (369.67,472.56) .. (369.67,472.56)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((371.92,474.04)
 .. controls (372.74,472.39) and (373.62,472.71) .. (374.30,470.23)
 .. controls (374.98,467.76) and (375.48,465.28) .. (373.82,462.62)
 .. controls (372.15,459.94) and (372.03,458.60) .. (370.22,458.41)
 .. controls (368.41,458.22) and (366.60,458.19) .. (365.14,458.17)
 .. controls (363.68,458.14) and (361.69,457.93) .. (361.69,457.93)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((365.14,458.17)
 .. controls (365.03,456.48) and (366.16,455.65) .. (365.18,452.75)
 .. controls (364.19,449.83) and (363.86,448.63) .. (362.26,447.21)
 .. controls (360.65,445.79) and (357.19,444.82) .. (355.54,444.60)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((360.29,445.60)
 .. controls (360.49,444.74) and (361.30,442.17) .. (361.17,439.38)
 .. controls (361.05,436.58) and (360.90,433.76) .. (358.90,431.75)
 .. controls (356.90,429.74) and (355.63,428.10) .. (352.32,427.46)
 .. controls (349.02,426.82) and (344.08,425.25) .. (342.79,425.57)
));
ATTR__id := "l34-5365-6397";
ATTR__height := -1;
drawoptions();
l_border_invisible(((350.71,401.90)
 .. controls (346.89,401.48) and (347.98,400.78) .. (346.71,400.58)
 .. controls (345.43,400.38) and (343.44,399.27) .. (340.90,397.26)
 .. controls (338.37,395.26) and (337.65,392.39) .. (336.58,390.06)
 .. controls (335.50,387.73) and (336.60,385.60) .. (337.16,383.64)
 .. controls (337.71,381.69) and (340.06,380.99) .. (342.61,378.15)
 .. controls (345.16,375.32) and (351.48,374.99) .. (355.63,375.00)
 .. controls (359.78,375.02) and (366.24,381.12) .. (367.15,384.73)
 .. controls (368.07,388.35) and (368.44,391.26) .. (367.94,395.63)
 .. controls (367.43,400.00) and (365.81,400.72) .. (362.55,402.48)
 .. controls (359.28,404.24) and (354.53,402.33) .. cycle
));
ATTR__id := "l37-5242-5867";
ATTR__height := -1;
drawoptions();
l_border_invisible(((344.09,304.45)
 .. controls (342.83,305.35) and (342.29,304.62) .. (340.48,305.33)
 .. controls (338.68,306.05) and (337.95,305.68) .. (335.96,304.05)
 .. controls (333.98,302.42) and (334.34,298.83) .. (335.79,296.67)
 .. controls (337.23,294.52) and (339.93,295.24) .. (341.37,295.96)
 .. controls (342.82,296.69) and (344.44,298.49) .. (345.34,299.94)
 .. controls (346.25,301.39) and (345.35,303.55) .. cycle
));
ATTR__id := "l38-5101-5602";
ATTR__height := -1;
drawoptions();
l_border_invisible(((312.49,259.75)
 .. controls (310.68,257.95) and (305.81,254.15) .. (305.09,251.45)
 .. controls (304.37,248.75) and (304.20,246.23) .. (306.54,245.15)
 .. controls (308.88,244.07) and (311.22,241.37) .. (313.92,243.90)
 .. controls (316.63,246.44) and (318.80,247.89) .. (319.70,251.32)
 .. controls (320.61,254.75) and (320.79,256.73) .. (319.89,258.17)
 .. controls (318.99,259.60) and (318.08,261.76) .. (316.10,260.85)
 .. controls (314.11,259.94) and (314.29,261.56) .. cycle
));
endfig;
beginfig(29);
draw_upscrap(1)(1,((410.18,594.14)
 .. controls (406.28,592.25) and (404.58,594.81) .. (402.36,591.33)
 .. controls (399.46,586.77) and (391.89,571.32) .. (388.16,563.56)
 .. controls (384.59,556.13) and (368.66,520.10) .. (366.35,513.39)
 .. controls (364.08,506.76) and (352.72,463.53) .. (350.52,458.90)
 .. controls (348.30,454.22) and (345.16,427.77) .. (343.55,422.39)
 .. controls (341.94,416.99) and (337.44,400.26) .. (336.19,395.06)
 .. controls (334.95,389.87) and (335.37,380.42) .. (336.67,375.45)
 .. controls (337.98,370.49) and (344.37,363.42) .. (346.37,361.84)
 .. controls (348.37,360.26) and (356.67,359.58) .. (349.53,353.72)
 .. controls (342.35,347.83) and (333.13,346.50) .. (330.25,344.51)
 .. controls (327.37,342.53) and (316.53,341.01) .. (319.66,328.00)
 .. controls (322.78,314.94) and (325.30,310.47) .. (323.70,302.03)
 .. controls (322.10,293.61) and (318.21,278.94) .. (314.99,270.71)
 .. controls (311.76,262.44) and (304.73,256.30) .. (297.17,251.62)
 .. controls (289.63,246.96) and (282.81,239.63) .. (270.20,244.10)
 .. controls (264.10,246.27) and (258.83,246.95) .. (251.44,244.77)
 .. controls (244.04,242.58) and (212.31,238.17) .. (209.97,239.06)
 .. controls (207.62,239.96) and (166.48,238.81) .. (158.19,242.04)
 .. controls (149.90,245.26) and (139.27,245.78) .. (136.92,247.75)
 .. controls (134.57,249.72) and (128.43,254.90) .. (118.55,246.30)
 .. controls (108.67,237.69) and (108.69,231.06) .. (104.92,227.12)
 .. controls (101.16,223.18) and (90.40,205.43) .. (88.06,202.19)
 .. controls (85.72,198.95) and (52.15,169.29) .. (46.92,165.68)
 .. controls (41.69,162.07) and (12.73,140.33) .. (8.77,138.17)
 .. controls (4.82,136.01) and (-23.28,119.43) .. (-32.29,107.36)
 .. controls (-41.30,95.27) and (-62.41,72.51) .. (-65.30,68.72)
 .. controls (-68.19,64.93) and (-116.96,17.77) .. (-124.68,11.13)
 .. controls (-132.40,4.50) and (-179.63,-47.52) .. (-184.85,-51.85)
 .. controls (-190.07,-56.17) and (-193.13,-66.79) .. (-196.01,-70.40)
),
1,((-196.01,-70.40)
 .. controls (-196.01,-70.40) and (-239.52,-130.19) .. (-252.53,-146.11)
 .. controls (-265.53,-162.02) and (-288.64,-180.85) .. (-303.08,-195.31)
 .. controls (-317.52,-209.78) and (-350.73,-245.19) .. (-369.49,-264.70)
 .. controls (-388.25,-284.20) and (-408.46,-309.47) .. (-420.00,-325.35)
 .. controls (-431.54,-341.22) and (-464.72,-378.03) .. (-464.72,-378.03)
),
0,((-464.72,-378.03)
 -- (-500.78,-430.68)
 -- (-519.54,-461.69)
 -- (-544.05,-492.70)
),
0,((-297.80,-629.49)
 -- (-267.54,-602.81)
 -- (-222.11,-534.30)
 -- (-201.87,-462.90)
),
1,((-201.87,-462.90)
 .. controls (-201.87,-462.90) and (-201.85,-445.59) .. (-199.65,-421.78)
 .. controls (-197.46,-397.97) and (-199.60,-380.66) .. (-198.86,-365.50)
 .. controls (-198.11,-350.35) and (-190.06,-273.82) .. (-190.02,-255.04)
 .. controls (-189.99,-236.26) and (-165.38,-185.67) .. (-158.88,-174.10)
 .. controls (-152.37,-162.54) and (-120.78,-108.58) .. (-120.78,-108.58)
),
1,((-120.78,-108.58)
 .. controls (-118.80,-104.43) and (-111.97,-97.42) .. (-108.55,-91.66)
 .. controls (-105.13,-85.91) and (-101.18,-83.04) .. (-95.80,-78.20)
 .. controls (-90.41,-73.36) and (-80.72,-65.84) .. (-76.05,-60.28)
 .. controls (-71.38,-54.72) and (-58.10,-42.71) .. (-53.06,-38.58)
 .. controls (-48.03,-34.45) and (-35.62,-20.43) .. (-32.38,-15.92)
 .. controls (-29.14,-11.42) and (-16.53,-0.78) .. (-9.13,8.97)
 .. controls (-1.73,18.72) and (28.76,48.55) .. (32.19,51.80)
 .. controls (35.61,55.04) and (41.74,62.08) .. (45.17,68.03)
 .. controls (48.59,73.97) and (59.01,84.20) .. (60.99,88.16)
 .. controls (62.96,92.11) and (86.86,113.81) .. (88.66,116.15)
 .. controls (90.46,118.49) and (105.22,131.27) .. (109.90,135.96)
 .. controls (114.59,140.64) and (121.26,145.69) .. (125.04,147.85)
 .. controls (128.82,150.01) and (129.72,150.19) .. (133.32,154.16)
 .. controls (136.93,158.13) and (151.35,170.03) .. (156.75,173.64)
 .. controls (162.16,177.25) and (173.66,176.14) .. (179.59,176.13)
 .. controls (185.52,176.11) and (211.96,184.18) .. (217.72,186.52)
 .. controls (223.48,188.86) and (262.43,199.60) .. (270.18,201.42)
 .. controls (277.93,203.23) and (293.23,206.64) .. (300.25,212.40)
 .. controls (307.26,218.15) and (314.27,230.56) .. (316.97,234.52)
 .. controls (319.68,238.50) and (325.10,245.19) .. (327.44,247.90)
 .. controls (329.79,250.61) and (329.79,252.23) .. (330.51,254.75)
 .. controls (331.23,257.27) and (336.07,265.16) .. (338.57,270.34)
 .. controls (341.06,275.52) and (345.17,281.23) .. (347.50,288.77)
 .. controls (349.84,296.34) and (352.56,301.05) .. (358.01,308.14)
 .. controls (363.45,315.22) and (365.61,316.30) .. (367.41,319.91)
 .. controls (369.21,323.50) and (369.34,336.38) .. (370.21,339.04)
 .. controls (371.08,341.69) and (374.93,349.45) .. (377.00,357.21)
 .. controls (379.07,365.00) and (378.49,372.49) .. (377.59,375.73)
 .. controls (376.69,378.96) and (377.95,382.58) .. (378.72,388.58)
 .. controls (379.49,394.62) and (382.89,405.12) .. (383.66,408.62)
 .. controls (384.43,412.12) and (388.44,417.98) .. (393.66,421.54)
 .. controls (398.79,425.05) and (400.99,435.76) .. (404.18,441.51)
 .. controls (407.30,447.16) and (416.80,462.28) .. (419.65,469.64)
 .. controls (422.48,476.96) and (421.66,478.79) .. (423.51,482.42)
 .. controls (425.36,486.05) and (428.13,491.75) .. (431.50,504.57)
 .. controls (434.86,517.33) and (453.92,558.23) .. (453.92,558.23)
));
draw_downscrap;
endfig;
beginfig(30);
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-120.78,-108.58)
 .. controls (-118.80,-104.43) and (-111.97,-97.42) .. (-108.55,-91.66)
 .. controls (-105.13,-85.91) and (-101.18,-83.04) .. (-95.80,-78.20)
 .. controls (-90.41,-73.36) and (-80.72,-65.84) .. (-76.05,-60.28)
 .. controls (-71.38,-54.72) and (-58.10,-42.71) .. (-53.06,-38.58)
 .. controls (-48.03,-34.45) and (-35.62,-20.43) .. (-32.38,-15.92)
 .. controls (-29.14,-11.42) and (-16.53,-0.78) .. (-9.13,8.97)
 .. controls (-1.73,18.72) and (28.76,48.55) .. (32.19,51.80)
 .. controls (35.61,55.04) and (41.74,62.08) .. (45.17,68.03)
 .. controls (48.59,73.97) and (59.01,84.20) .. (60.99,88.16)
 .. controls (62.96,92.11) and (86.86,113.81) .. (88.66,116.15)
 .. controls (90.46,118.49) and (105.22,131.27) .. (109.90,135.96)
 .. controls (114.59,140.64) and (121.26,145.69) .. (125.04,147.85)
 .. controls (128.82,150.01) and (129.72,150.19) .. (133.32,154.16)
 .. controls (136.93,158.13) and (151.35,170.03) .. (156.75,173.64)
 .. controls (162.16,177.25) and (173.66,176.14) .. (179.59,176.13)
 .. controls (185.52,176.11) and (211.96,184.18) .. (217.72,186.52)
 .. controls (223.48,188.86) and (262.43,199.60) .. (270.18,201.42)
 .. controls (277.93,203.23) and (293.23,206.64) .. (300.25,212.40)
 .. controls (307.26,218.15) and (314.27,230.56) .. (316.97,234.52)
 .. controls (319.68,238.50) and (325.10,245.19) .. (327.44,247.90)
 .. controls (329.79,250.61) and (329.79,252.23) .. (330.51,254.75)
 .. controls (331.23,257.27) and (336.07,265.16) .. (338.57,270.34)
 .. controls (341.06,275.52) and (345.17,281.23) .. (347.50,288.77)
 .. controls (349.84,296.34) and (352.56,301.05) .. (358.01,308.14)
 .. controls (363.45,315.22) and (365.61,316.30) .. (367.41,319.91)
 .. controls (369.21,323.50) and (369.34,336.38) .. (370.21,339.04)
 .. controls (371.08,341.69) and (374.93,349.45) .. (377.00,357.21)
 .. controls (379.07,365.00) and (378.49,372.49) .. (377.59,375.73)
 .. controls (376.69,378.96) and (377.95,382.58) .. (378.72,388.58)
 .. controls (379.49,394.62) and (382.89,405.12) .. (383.66,408.62)
 .. controls (384.43,412.12) and (388.44,417.98) .. (393.66,421.54)
 .. controls (398.79,425.05) and (400.99,435.76) .. (404.18,441.51)
 .. controls (407.30,447.16) and (416.80,462.28) .. (419.65,469.64)
 .. controls (422.48,476.96) and (421.66,478.79) .. (423.51,482.42)
 .. controls (425.36,486.05) and (428.13,491.75) .. (431.50,504.57)
 .. controls (434.86,517.33) and (453.92,558.23) .. (453.92,558.23)
));
drawoptions();
p_stalactites((-181.46,-28.86),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-160.62,-7.68),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-145.91,8.81),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-127.96,27.10),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-53.06,-63.96),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-35.81,-45.64),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-23.93,-33.05),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-10.61,-17.91),0.0,1.00,(0,0));
drawoptions();
p_stalactites((4.18,-0.23),0.0,1.00,(0,0));
drawoptions();
p_stalactites((55.74,56.08),0.0,1.00,(0,0));
drawoptions();
p_stalactites((71.21,72.62),0.0,1.00,(0,0));
drawoptions();
p_stalactites((85.95,89.50),0.0,1.00,(0,0));
drawoptions();
p_stalactites((101.41,104.95),0.0,1.00,(0,0));
drawoptions();
p_stalactites((117.98,122.24),0.0,1.00,(0,0));
drawoptions();
p_stalactites((135.99,138.81),0.0,1.00,(0,0));
drawoptions();
p_stalactites((152.21,153.24),0.0,1.00,(0,0));
drawoptions();
p_stalactites((184.95,161.49),0.0,1.00,(0,0));
drawoptions();
p_stalactites((203.66,167.96),0.0,1.00,(0,0));
drawoptions();
p_stalactites((224.54,174.08),0.0,1.00,(0,0));
drawoptions();
p_stalactites((246.53,182.41),0.0,1.00,(0,0));
drawoptions();
p_stalactites((268.89,188.95),0.0,1.00,(0,0));
drawoptions();
p_stalactites((319.28,211.97),0.0,1.00,(0,0));
drawoptions();
p_stalactites((280.05,259.88),0.0,1.00,(0,0));
drawoptions();
p_stalactites((246.17,257.66),0.0,1.00,(0,0));
drawoptions();
p_stalactites((223.81,253.27),0.0,1.00,(0,0));
drawoptions();
p_stalactites((199.32,251.09),0.0,1.00,(0,0));
drawoptions();
p_stalactites((176.31,251.84),0.0,1.00,(0,0));
drawoptions();
p_stalactites((149.68,254.74),0.0,1.00,(0,0));
drawoptions();
p_stalactites((101.45,244.67),0.0,1.00,(0,0));
drawoptions();
p_stalactites((85.66,227.11),0.0,1.00,(0,0));
drawoptions();
p_stalactites((70.56,207.35),0.0,1.00,(0,0));
drawoptions();
p_stalactites((51.44,191.80),0.0,1.00,(0,0));
drawoptions();
p_stalactites((38.45,183.12),0.0,1.00,(0,0));
drawoptions();
p_stalactites((21.51,168.33),0.0,1.00,(0,0));
drawoptions();
p_stalactites((2.06,157.53),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-16.66,145.65),0.0,1.00,(0,0));
drawoptions();
p_stalactites((300.73,317.52),0.0,1.00,(0,0));
drawoptions();
p_rimstonepool((251.64,228.96),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((376.53,418.62),161.2,1.00,(0,0));
drawoptions();
p_rimstonepool((366.66,416.22),161.2,1.00,(0,0));
drawoptions();
p_rimstonepool((258.85,213.85),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((239.73,225.31),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((246.58,208.04),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((228.54,201.49),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((226.38,222.02),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((214.12,195.35),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((209.81,209.40),106.3,1.00,(0,0));
drawoptions();
p_rimstonepool((205.84,225.23),95.9,1.00,(0,0));
drawoptions();
p_rimstonepool((209.81,209.40),95.9,1.00,(0,0));
drawoptions();
p_rimstonepool((214.12,195.35),107.4,1.00,(0,0));
drawoptions();
p_rimstonepool((198.30,192.13),107.4,1.00,(0,0));
drawoptions();
p_rimstonepool((194.35,207.64),107.4,1.00,(0,0));
drawoptions();
p_rimstonepool((190.03,223.48),92.5,1.00,(0,0));
drawoptions();
p_rimstonepool((184.29,190.01),105.0,1.00,(0,0));
drawoptions();
p_rimstonepool((178.92,209.15),108.3,1.00,(0,0));
drawoptions();
p_rimstonepool((173.88,225.70),113.7,1.00,(0,0));
ATTR__id := "l16-2212-1612";
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-201.87,-462.90)
 .. controls (-201.87,-462.90) and (-201.85,-445.59) .. (-199.65,-421.78)
 .. controls (-197.46,-397.97) and (-199.60,-380.66) .. (-198.86,-365.50)
 .. controls (-198.11,-350.35) and (-190.06,-273.82) .. (-190.02,-255.04)
 .. controls (-189.99,-236.26) and (-165.38,-185.67) .. (-158.88,-174.10)
 .. controls (-152.37,-162.54) and (-120.78,-108.58) .. (-120.78,-108.58)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_invisible(((-297.80,-629.49)
 -- (-267.54,-602.81)
 -- (-222.11,-534.30)
 -- (-201.87,-462.90)
));
ATTR__height := -1;
drawoptions();
l_wall_invisible(((-464.72,-378.03)
 -- (-500.78,-430.68)
 -- (-519.54,-461.69)
 -- (-544.05,-492.70)
));
ATTR__height := -1;
drawoptions();
l_wall_unsurveyed(((-196.01,-70.40)
 .. controls (-196.01,-70.40) and (-239.52,-130.19) .. (-252.53,-146.11)
 .. controls (-265.53,-162.02) and (-288.64,-180.85) .. (-303.08,-195.31)
 .. controls (-317.52,-209.78) and (-350.73,-245.19) .. (-369.49,-264.70)
 .. controls (-388.25,-284.20) and (-408.46,-309.47) .. (-420.00,-325.35)
 .. controls (-431.54,-341.22) and (-464.72,-378.03) .. (-464.72,-378.03)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((410.18,594.14)
 .. controls (406.28,592.25) and (404.58,594.81) .. (402.36,591.33)
 .. controls (399.46,586.77) and (391.89,571.32) .. (388.16,563.56)
 .. controls (384.59,556.13) and (368.66,520.10) .. (366.35,513.39)
 .. controls (364.08,506.76) and (352.72,463.53) .. (350.52,458.90)
 .. controls (348.30,454.22) and (345.16,427.77) .. (343.55,422.39)
 .. controls (341.94,416.99) and (337.44,400.26) .. (336.19,395.06)
 .. controls (334.95,389.87) and (335.37,380.42) .. (336.67,375.45)
 .. controls (337.98,370.49) and (344.37,363.42) .. (346.37,361.84)
 .. controls (348.37,360.26) and (356.67,359.58) .. (349.53,353.72)
 .. controls (342.35,347.83) and (333.13,346.50) .. (330.25,344.51)
 .. controls (327.37,342.53) and (316.53,341.01) .. (319.66,328.00)
 .. controls (322.78,314.94) and (325.30,310.47) .. (323.70,302.03)
 .. controls (322.10,293.61) and (318.21,278.94) .. (314.99,270.71)
 .. controls (311.76,262.44) and (304.73,256.30) .. (297.17,251.62)
 .. controls (289.63,246.96) and (282.81,239.63) .. (270.20,244.10)
 .. controls (264.10,246.27) and (258.83,246.95) .. (251.44,244.77)
 .. controls (244.04,242.58) and (212.31,238.17) .. (209.97,239.06)
 .. controls (207.62,239.96) and (166.48,238.81) .. (158.19,242.04)
 .. controls (149.90,245.26) and (139.27,245.78) .. (136.92,247.75)
 .. controls (134.57,249.72) and (128.43,254.90) .. (118.55,246.30)
 .. controls (108.67,237.69) and (108.69,231.06) .. (104.92,227.12)
 .. controls (101.16,223.18) and (90.40,205.43) .. (88.06,202.19)
 .. controls (85.72,198.95) and (52.15,169.29) .. (46.92,165.68)
 .. controls (41.69,162.07) and (12.73,140.33) .. (8.77,138.17)
 .. controls (4.82,136.01) and (-23.28,119.43) .. (-32.29,107.36)
 .. controls (-41.30,95.27) and (-62.41,72.51) .. (-65.30,68.72)
 .. controls (-68.19,64.93) and (-116.96,17.77) .. (-124.68,11.13)
 .. controls (-132.40,4.50) and (-179.63,-47.52) .. (-184.85,-51.85)
 .. controls (-190.07,-56.17) and (-193.13,-66.79) .. (-196.01,-70.40)
));
drawoptions();
p_crystal((-100.62,52.99),0.0,1.00,(0,0));
drawoptions();
p_crystal((-85.13,67.76),0.0,1.00,(0,0));
drawoptions();
p_crystal((-69.99,84.72),0.0,1.00,(0,0));
drawoptions();
p_crystal((-54.48,101.69),0.0,1.00,(0,0));
endfig;
beginfig(31);
drawoptions();
p_label(btex \thlabel\thlargesize \thfb\char70 \char97 \char116 \char99 \char97 \char109 \char112 \ \char70 \char97 \char105 \char108 \char117 \char114 \char101 \mainfont{} etex,(67.12,-143.15),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char115 \char113 \char117 \char101 \char101 \char122 \char101 \mainfont{} etex,(296.85,362.07),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char66 \char101 \char100 \char100 \char105 \char110 \char103 \ \char80 \char108 \char97 \char110 \char101 \mainfont{} etex,(-159.34,-428.27),0.0,0);
drawoptions();
p_label.rt(btex \thlabel\thnormalsize \thfb\char84 \char111 \char111 \ \char84 \char105 \char103 \char104 \char116 \mainfont{} etex,(-189.01,-564.58),0.0,0);
endfig;
background:=(1.00000,0.37750,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.37750, 0.25000);
current_scrap := "lumioSP1@lumio.romeo";
ATTR__scrap := "lumioSP1";
beginfig(32);
ATTR__survey := "lumio.romeo";
current_src := "lumio.th2 [599]";
string area_border[];
area_border[1] := "l93-3770-5546";
area_border[2] := "l38-3808-5660";
drawoptions();
a_blocks(buildcycle(((286.65,242.69)
 -- (308.79,209.57)
 -- (337.76,220.32)
 -- (336.67,236.29)
),
((336.67,236.29)
 .. controls (336.67,236.29) and (331.45,237.54) .. (328.57,237.90)
 .. controls (325.68,238.26) and (322.26,240.06) .. (319.92,240.24)
 .. controls (317.58,240.42) and (316.68,242.04) .. (317.22,245.46)
 .. controls (317.77,248.88) and (320.28,247.08) .. (319.21,252.13)
 .. controls (318.13,257.18) and (318.85,256.10) .. (318.13,256.64)
 .. controls (317.41,257.18) and (315.61,255.92) .. (313.45,254.66)
 .. controls (311.29,253.40) and (302.29,248.56) .. (299.96,247.85)
 .. controls (297.62,247.14) and (288.81,243.76) .. (286.65,242.69)
)));
current_src := "lumio.th2 [590]";
string area_border[];
area_border[1] := "l29-3492-6199";
area_border[2] := "l91-3545-6308";
area_border[3] := "l87-3932-6480";
area_border[4] := "l88-4018-6279";
area_border[5] := "l38-3808-5660";
area_border[6] := "l90-3627-5642";
drawoptions();
a_blocks(buildcycle(((246.92,356.40)
 .. controls (246.92,356.40) and (247.99,354.42) .. (247.45,351.88)
 .. controls (246.90,349.34) and (245.64,346.61) .. (245.63,344.44)
 .. controls (245.63,342.27) and (245.09,338.12) .. (243.46,338.10)
 .. controls (241.84,338.09) and (238.23,338.06) .. (238.23,334.99)
 .. controls (238.23,331.94) and (238.77,328.89) .. (237.51,327.80)
 .. controls (236.25,326.72) and (234.27,325.27) .. (233.37,325.09)
 .. controls (232.47,324.90) and (230.13,324.18) .. (230.13,324.18)
 .. controls (230.13,324.18) and (230.67,319.53) .. (230.14,317.74)
 .. controls (229.60,315.95) and (227.81,311.12) .. (224.75,310.58)
 .. controls (221.69,310.04) and (214.30,314.16) .. (214.30,314.16)
),
((246.92,356.40)
 -- (289.04,401.07)
),
((348.72,379.50)
 .. controls (334.43,404.80) and (289.04,401.07) .. (289.04,401.07)
),
((348.72,379.50)
 -- (323.37,322.07)
 -- (365.89,288.18)
 -- (336.67,236.29)
),
((336.67,236.29)
 .. controls (336.67,236.29) and (331.45,237.54) .. (328.57,237.90)
 .. controls (325.68,238.26) and (322.26,240.06) .. (319.92,240.24)
 .. controls (317.58,240.42) and (316.68,242.04) .. (317.22,245.46)
 .. controls (317.77,248.88) and (320.28,247.08) .. (319.21,252.13)
 .. controls (318.13,257.18) and (318.85,256.10) .. (318.13,256.64)
 .. controls (317.41,257.18) and (315.61,255.92) .. (313.45,254.66)
 .. controls (311.29,253.40) and (302.29,248.56) .. (299.96,247.85)
 .. controls (297.62,247.14) and (288.81,243.76) .. (286.65,242.69)
),
((286.65,242.69)
 -- (237.02,251.86)
 -- (214.30,314.16)
)));
current_src := "lumio.th2 [560]";
string area_border[];
area_border[1] := "l99-4135-6955";
drawoptions();
a_blocks(buildcycle(((297.27,418.37)
 -- (349.26,399.15)
 -- (368.03,447.38)
 -- (322.83,477.25)
 -- cycle
)));
current_src := "lumio.th2 [503]";
string area_border[];
area_border[1] := "l116-4365-7440";
area_border[2] := "l110-4061-7415";
area_border[3] := "l37-4253-7640";
drawoptions();
a_sand(buildcycle(((332.23,533.56)
 .. controls (332.23,533.56) and (327.21,512.63) .. (355.52,520.28)
 .. controls (384.28,528.06) and (371.43,470.81) .. (410.66,497.08)
 .. controls (438.60,515.78) and (399.06,552.04) .. (399.06,552.04)
 .. controls (399.06,552.04) and (383.55,533.53) .. (375.45,534.69)
 .. controls (368.18,535.72) and (344.16,547.13) .. (367.68,567.72)
 .. controls (384.35,582.32) and (388.76,580.58) .. (396.31,566.39)
 .. controls (402.71,554.38) and (411.32,607.50) .. (411.32,607.50)
 -- (406.78,616.96)
),
((370.85,610.42)
 -- (332.23,533.56)
),
((370.85,610.42)
 .. controls (371.20,609.84) and (373.12,608.52) .. (373.80,608.30)
 .. controls (374.47,608.08) and (378.32,607.01) .. (380.31,607.60)
 .. controls (382.37,608.21) and (383.37,607.87) .. (384.66,607.52)
 .. controls (385.93,607.18) and (387.72,608.56) .. (389.07,609.57)
 .. controls (390.42,610.57) and (391.19,611.68) .. (393.25,611.36)
 .. controls (395.28,611.03) and (397.07,610.38) .. (398.30,611.21)
 .. controls (399.50,612.02) and (399.49,614.42) .. (401.12,615.36)
 .. controls (402.68,616.25) and (402.75,616.65) .. (404.30,617.10)
 .. controls (405.83,617.53) and (406.78,616.96) .. (406.78,616.96)
)));
current_src := "lumio.th2 [310]";
string area_border[];
area_border[1] := "l80-2903-6467";
area_border[2] := "l74-2967-6501";
area_border[3] := "l76-3250-6435";
area_border[4] := "l30-3433-6204";
area_border[5] := "l77-3294-6130";
area_border[6] := "l29-2876-6009";
drawoptions();
a_sand(buildcycle(((116.77,341.65)
 -- (130.23,385.06)
 -- (146.41,400.64)
),
((198.72,392.01)
 .. controls (199.61,388.04) and (194.55,386.76) .. (190.06,390.15)
 .. controls (182.49,395.87) and (178.87,397.44) .. (168.40,398.59)
 .. controls (159.10,399.62) and (146.41,400.64) .. (146.41,400.64)
),
((237.72,354.53)
 -- (198.72,392.01)
),
((237.72,354.53)
 .. controls (237.72,354.53) and (237.17,352.53) .. (236.08,349.80)
 .. controls (235.00,347.07) and (234.27,346.34) .. (233.55,345.07)
 .. controls (232.83,343.80) and (232.11,343.97) .. (230.12,342.15)
 .. controls (228.14,340.34) and (222.91,335.39) .. (222.91,335.39)
),
((222.91,335.39)
 -- (175.25,329.16)
 -- (155.77,297.68)
),
((116.77,341.65)
 .. controls (116.77,341.65) and (121.80,340.36) .. (131.88,339.62)
 .. controls (141.95,338.88) and (145.56,342.13) .. (145.01,335.44)
 .. controls (144.46,328.74) and (145.89,324.03) .. (140.48,321.68)
 .. controls (135.08,319.33) and (131.49,321.70) .. (132.56,317.18)
 .. controls (133.63,312.65) and (135.78,309.39) .. (137.94,306.31)
 .. controls (140.10,303.24) and (141.00,304.50) .. (143.16,303.23)
 .. controls (145.32,301.97) and (155.77,297.68) .. (155.77,297.68)
)));
current_src := "lumio.th2 [181]";
string area_border[];
area_border[1] := "l29-2876-6009";
area_border[2] := "l2-2921-5866";
area_border[3] := "l28-2822-5750";
area_border[4] := "l3-2689-6022";
drawoptions();
a_blocks(buildcycle(((116.77,341.65)
 .. controls (116.77,341.65) and (121.80,340.36) .. (131.88,339.62)
 .. controls (141.95,338.88) and (145.56,342.13) .. (145.01,335.44)
 .. controls (144.46,328.74) and (145.89,324.03) .. (140.48,321.68)
 .. controls (135.08,319.33) and (131.49,321.70) .. (132.56,317.18)
 .. controls (133.63,312.65) and (135.78,309.39) .. (137.94,306.31)
 .. controls (140.10,303.24) and (141.00,304.50) .. (143.16,303.23)
 .. controls (145.32,301.97) and (155.77,297.68) .. (155.77,297.68)
),
((-274.63,-633.14)
 .. controls (-273.37,-629.90) and (-275.53,-625.94) .. (-273.37,-624.32)
 .. controls (-271.21,-622.70) and (-268.15,-620.54) .. (-264.19,-616.58)
 .. controls (-260.23,-612.61) and (-258.25,-604.69) .. (-255.01,-602.53)
 .. controls (-251.77,-600.37) and (-230.89,-596.40) .. (-227.65,-596.94)
 .. controls (-224.41,-597.48) and (-214.33,-596.21) .. (-209.29,-597.65)
 .. controls (-204.24,-599.08) and (-185.70,-602.85) .. (-182.82,-600.86)
 .. controls (-179.94,-598.88) and (-179.94,-601.04) .. (-178.14,-589.89)
 .. controls (-176.34,-578.73) and (-174.90,-555.87) .. (-174.36,-551.73)
 .. controls (-173.82,-547.59) and (-172.38,-515.01) .. (-169.68,-504.76)
 .. controls (-166.98,-494.51) and (-155.65,-465.20) .. (-152.95,-459.80)
 .. controls (-150.25,-454.41) and (-136.75,-428.47) .. (-134.77,-423.97)
 .. controls (-132.79,-419.46) and (-116.41,-378.77) .. (-109.57,-369.77)
 .. controls (-102.73,-360.78) and (-102.01,-351.96) .. (-100.39,-347.28)
 .. controls (-98.77,-342.60) and (-95.53,-332.33) .. (-95.53,-328.19)
 .. controls (-95.53,-324.05) and (-95.17,-309.28) .. (-92.65,-305.68)
 .. controls (-90.13,-302.07) and (-85.45,-286.23) .. (-85.63,-279.76)
 .. controls (-85.81,-273.28) and (-81.68,-252.96) .. (-80.78,-245.59)
 .. controls (-79.88,-238.21) and (-78.08,-235.33) .. (-75.57,-230.65)
 .. controls (-73.05,-225.97) and (-62.61,-208.88) .. (-60.09,-202.75)
 .. controls (-57.57,-196.63) and (-41.17,-162.38) .. (-39.37,-155.89)
 .. controls (-37.56,-149.41) and (-28.21,-126.75) .. (-26.23,-122.43)
 .. controls (-24.25,-118.11) and (-19.57,-107.85) .. (-15.60,-101.00)
 .. controls (-11.64,-94.15) and (0.61,-78.10) .. (4.75,-67.29)
 .. controls (8.90,-56.49) and (11.23,-42.46) .. (11.77,-38.69)
 .. controls (12.31,-34.91) and (14.99,-9.24) .. (14.63,-2.95)
 .. controls (14.27,3.35) and (12.29,14.15) .. (16.62,26.60)
 .. controls (20.95,39.05) and (27.98,49.70) .. (29.06,55.28)
 .. controls (30.14,60.86) and (35.54,73.45) .. (36.44,78.13)
 .. controls (37.34,82.80) and (38.96,102.24) .. (44.01,111.62)
 .. controls (49.05,121.00) and (55.18,136.14) .. (58.96,142.25)
 .. controls (62.74,148.36) and (69.03,159.31) .. (74.07,162.37)
 .. controls (79.11,165.44) and (87.76,167.63) .. (90.64,176.08)
 .. controls (93.52,184.55) and (95.15,192.67) .. (97.67,197.19)
 .. controls (100.20,201.71) and (106.15,218.51) .. (111.74,229.52)
 .. controls (117.32,240.51) and (125.59,255.77) .. (128.64,260.43)
 .. controls (131.69,265.09) and (137.25,278.68) .. (139.94,282.08)
 .. controls (142.64,285.47) and (149.46,295.86) .. (150.90,300.72)
 .. controls (152.34,305.58) and (152.35,314.25) .. (156.50,319.70)
 .. controls (160.66,325.14) and (178.33,343.24) .. (181.03,345.40)
 .. controls (183.73,347.56) and (189.85,354.95) .. (195.24,352.76)
 .. controls (200.64,350.57) and (211.05,343.99) .. (213.02,342.53)
 .. controls (215.00,341.07) and (222.91,335.39) .. (222.91,335.39)
 .. controls (222.91,335.39) and (214.63,333.86) .. (214.46,325.79)
 .. controls (214.30,317.74) and (216.83,310.22) .. (219.36,304.13)
 .. controls (221.89,298.05) and (233.78,276.33) .. (235.94,274.17)
 .. controls (238.10,272.01) and (247.10,260.12) .. (253.75,256.14)
 .. controls (260.40,252.16) and (275.50,245.98) .. (279.82,245.24)
 .. controls (284.13,244.50) and (289.35,246.82) .. (292.04,245.18)
 .. controls (294.74,243.55) and (299.77,240.47) .. (301.93,238.84)
 .. controls (304.09,237.21) and (304.99,237.03) .. (304.09,232.18)
 .. controls (303.20,227.34) and (302.12,227.34) .. (304.82,223.56)
 .. controls (307.52,219.79) and (319.41,212.78) .. (326.42,220.13)
 .. controls (333.44,227.49) and (334.87,238.81) .. (336.13,244.03)
 .. controls (337.39,249.25) and (339.02,255.92) .. (342.08,258.45)
 .. controls (345.14,260.98) and (353.26,269.67) .. (354.70,272.93)
 .. controls (356.14,276.18) and (360.12,282.53) .. (357.24,288.48)
 .. controls (354.36,294.44) and (354.36,294.26) .. (345.35,297.83)
 .. controls (336.35,301.41) and (326.62,304.61) .. (323.73,307.47)
 .. controls (320.84,310.33) and (306.07,315.66) .. (309.14,325.07)
 .. controls (312.22,334.52) and (320.37,348.19) .. (323.26,352.93)
 .. controls (326.15,357.66) and (333.38,380.08) .. (335.36,383.69)
 .. controls (337.35,387.30) and (341.67,399.38) .. (343.12,401.74)
 .. controls (344.56,404.10) and (356.34,437.36) .. (359.40,445.43)
 .. controls (362.41,453.39) and (374.35,467.45) .. (375.93,471.66)
 .. controls (377.54,475.92) and (380.48,483.51) .. (386.30,489.88)
 .. controls (392.25,496.41) and (412.66,511.01) .. (404.82,528.57)
 .. controls (396.96,546.16) and (394.84,547.61) .. (394.36,552.37)
 .. controls (393.88,557.08) and (393.96,566.76) .. (394.34,571.36)
 .. controls (394.72,575.92) and (402.60,588.51) .. (402.80,591.14)
 .. controls (403.00,593.78) and (400.78,593.88) .. (400.71,600.13)
 .. controls (400.63,606.45) and (396.16,606.91) .. (401.08,612.71)
 .. controls (405.33,617.73) and (410.03,618.64) .. (414.01,621.43)
 .. controls (419.86,625.53) and (424.86,637.72) .. (428.52,644.21)
),
((87.26,305.52)
 .. controls (87.26,305.52) and (89.96,303.89) .. (91.04,296.50)
 .. controls (92.12,289.11) and (96.25,285.32) .. (93.92,277.77)
 .. controls (91.58,270.22) and (91.04,256.71) .. (96.98,257.61)
 .. controls (102.92,258.50) and (114.07,262.97) .. (119.64,264.39)
 .. controls (125.22,265.82) and (137.81,267.41) .. (137.81,267.41)
),
((405.00,654.29)
 .. controls (398.81,646.81) and (396.72,647.16) .. (388.59,637.72)
 .. controls (380.42,628.24) and (374.64,616.81) .. (371.22,609.56)
 .. controls (368.46,603.72) and (364.29,596.44) .. (362.24,591.79)
 .. controls (360.15,587.03) and (357.37,575.36) .. (355.61,571.05)
 .. controls (353.82,566.64) and (344.95,541.91) .. (343.23,535.85)
 .. controls (341.52,529.77) and (335.49,523.72) .. (334.28,514.27)
 .. controls (333.08,504.87) and (332.50,500.94) .. (331.55,495.18)
 .. controls (330.61,489.46) and (327.54,485.46) .. (325.52,476.66)
 .. controls (323.49,467.87) and (321.09,457.39) .. (320.35,453.88)
 .. controls (319.60,450.37) and (311.17,432.55) .. (309.70,427.76)
 .. controls (308.24,423.00) and (304.09,416.48) .. (302.11,412.00)
 .. controls (300.15,407.54) and (295.87,397.96) .. (294.27,391.39)
 .. controls (292.67,384.79) and (287.81,379.43) .. (286.38,375.29)
 .. controls (284.94,371.15) and (277.19,360.85) .. (276.47,360.13)
 .. controls (275.74,359.40) and (275.74,355.80) .. (264.22,355.58)
 .. controls (252.68,355.37) and (244.75,354.21) .. (240.60,353.64)
 .. controls (236.45,353.07) and (228.34,354.30) .. (224.22,359.57)
 .. controls (220.09,364.84) and (210.03,373.93) .. (206.98,377.19)
 .. controls (203.93,380.45) and (199.97,387.14) .. (194.21,390.54)
 .. controls (188.44,393.94) and (179.96,401.08) .. (174.54,401.38)
 .. controls (169.13,401.68) and (160.11,403.94) .. (154.87,402.46)
 .. controls (149.65,400.99) and (141.01,386.61) .. (135.81,379.83)
 .. controls (130.61,373.06) and (131.33,365.17) .. (128.10,356.75)
 .. controls (124.87,348.30) and (117.31,338.76) .. (114.42,332.27)
 .. controls (111.54,325.78) and (96.61,309.26) .. (91.40,303.16)
 .. controls (86.18,297.06) and (75.57,293.14) .. (72.70,286.30)
 .. controls (69.82,279.45) and (67.12,278.38) .. (71.07,269.89)
 .. controls (75.03,261.41) and (77.72,250.40) .. (77.72,246.79)
 .. controls (77.71,243.18) and (75.89,225.64) .. (72.64,217.49)
 .. controls (69.39,209.34) and (60.55,192.89) .. (56.23,186.77)
 .. controls (51.91,180.65) and (42.74,174.75) .. (40.04,170.45)
 .. controls (37.35,166.15) and (26.55,153.58) .. (22.95,147.82)
 .. controls (19.35,142.05) and (13.76,130.86) .. (13.04,128.51)
 .. controls (12.32,126.16) and (7.08,112.98) .. (6.00,108.47)
 .. controls (4.92,103.97) and (4.74,103.97) .. (0.42,100.91)
 .. controls (-3.90,97.86) and (-7.86,96.25) .. (-7.86,92.65)
 .. controls (-7.85,89.06) and (-5.88,88.16) .. (-4.79,83.66)
 .. controls (-3.71,79.17) and (-0.47,76.65) .. (-1.73,70.73)
 .. controls (-2.98,64.80) and (-9.46,60.32) .. (-12.88,55.64)
 .. controls (-16.30,50.97) and (-18.28,42.86) .. (-19.18,38.18)
 .. controls (-20.08,33.50) and (-18.11,24.30) .. (-19.01,17.09)
 .. controls (-19.91,9.89) and (-22.43,5.04) .. (-23.69,0.36)
 .. controls (-24.95,-4.32) and (-25.67,-15.47) .. (-29.27,-23.56)
 .. controls (-32.87,-31.65) and (-44.57,-46.96) .. (-46.19,-51.11)
 .. controls (-47.82,-55.26) and (-55.75,-73.48) .. (-57.91,-78.71)
 .. controls (-60.07,-83.93) and (-64.40,-88.25) .. (-62.06,-94.56)
 .. controls (-59.72,-100.87) and (-55.58,-107.71) .. (-58.10,-113.28)
 .. controls (-60.61,-118.85) and (-62.95,-133.94) .. (-65.29,-143.48)
 .. controls (-67.63,-153.02) and (-71.77,-165.81) .. (-72.68,-170.31)
 .. controls (-73.58,-174.82) and (-75.20,-185.28) .. (-81.32,-190.68)
 .. controls (-87.44,-196.08) and (-98.42,-203.82) .. (-99.86,-207.96)
 .. controls (-101.30,-212.10) and (-105.80,-228.49) .. (-106.88,-231.73)
 .. controls (-107.96,-234.97) and (-118.40,-244.86) .. (-121.46,-251.51)
 .. controls (-124.51,-258.16) and (-132.79,-270.93) .. (-134.41,-277.23)
 .. controls (-136.03,-283.53) and (-138.19,-296.14) .. (-136.75,-303.71)
 .. controls (-135.31,-311.28) and (-131.18,-323.17) .. (-130.82,-328.94)
 .. controls (-130.46,-334.70) and (-130.28,-341.72) .. (-137.66,-350.72)
 .. controls (-145.03,-359.70) and (-150.07,-369.95) .. (-156.91,-379.12)
 .. controls (-163.75,-388.30) and (-170.95,-402.52) .. (-172.75,-408.29)
 .. controls (-174.55,-414.05) and (-184.99,-432.42) .. (-187.87,-437.64)
 .. controls (-190.74,-442.86) and (-205.32,-462.46) .. (-206.94,-465.34)
 .. controls (-208.56,-468.21) and (-221.34,-487.65) .. (-230.16,-495.58)
 .. controls (-238.98,-503.50) and (-250.50,-509.99) .. (-256.44,-512.15)
 .. controls (-262.38,-514.31) and (-278.40,-523.12) .. (-281.64,-531.76)
 .. controls (-284.88,-540.41) and (-286.50,-550.13) .. (-285.78,-557.33)
 .. controls (-285.06,-564.53) and (-282.73,-575.52) .. (-283.81,-581.10)
 .. controls (-284.89,-586.68) and (-285.79,-591.72) .. (-289.03,-594.42)
 .. controls (-292.27,-597.12) and (-296.23,-600.00) .. (-296.23,-600.00)
)));
current_src := "lumio.th2 [85]";
string area_border[];
area_border[1] := "l33-654-1261";
area_border[2] := "l64-630-1464";
area_border[3] := "l51-1555-2955";
area_border[4] := "l65-1675-3232";
area_border[5] := "l59-1721-3241";
area_border[6] := "l66-1738-3654";
area_border[7] := "l62-1845-4063";
area_border[8] := "l61-1915-4187";
area_border[9] := "l63-2243-4056";
area_border[10] := "l50-1016-961";
area_border[11] := "l67-806-946";
drawoptions();
a_sand(buildcycle(((-284.70,-525.28)
 .. controls (-284.70,-525.28) and (-280.92,-529.96) .. (-274.80,-535.73)
 .. controls (-268.69,-541.50) and (-265.81,-544.39) .. (-257.53,-542.41)
 .. controls (-249.25,-540.44) and (-251.05,-533.77) .. (-243.85,-536.66)
 .. controls (-236.65,-539.54) and (-232.51,-533.77) .. (-228.55,-540.80)
 .. controls (-224.59,-547.82) and (-226.03,-549.80) .. (-225.49,-557.18)
 .. controls (-224.95,-564.56) and (-220.27,-568.33) .. (-221.89,-577.33)
 .. controls (-223.51,-586.32) and (-243.67,-602.34) .. (-243.67,-602.34)
),
((-284.70,-525.28)
 -- (-164.83,-376.42)
 -- (-136.93,-265.17)
 -- (-107.96,-233.17)
),
((-80.24,-190.68)
 .. controls (-76.29,-191.95) and (-65.31,-201.32) .. (-66.57,-207.98)
 .. controls (-67.83,-214.64) and (-69.09,-210.50) .. (-82.05,-231.19)
 .. controls (-95.00,-251.89) and (-107.96,-233.17) .. (-107.96,-233.17)
),
((-80.24,-190.68)
 .. controls (-80.24,-190.68) and (-91.04,-185.63) .. (-79.34,-188.52)
),
((-79.34,-188.52)
 .. controls (-79.34,-188.52) and (-53.24,-184.91) .. (-70.69,-164.01)
),
((-70.69,-164.01)
 .. controls (-70.69,-164.01) and (-74.29,-93.10) .. (-60.61,-74.01)
),
((-56.27,-49.48)
 -- (-60.61,-74.01)
),
((-56.27,-49.48)
 .. controls (-56.27,-49.48) and (9.59,-5.64) .. (27.25,-23.77)
),
((27.25,-23.77)
 -- (-23.88,-158.76)
 -- (-68.72,-255.29)
 -- (-92.65,-352.31)
 -- (-132.79,-455.12)
 -- (-157.08,-520.95)
 -- (-173.46,-605.17)
 -- (-189.12,-606.81)
 -- (-195.96,-601.42)
),
((-232.69,-597.66)
 .. controls (-232.69,-597.66) and (-229.63,-591.36) .. (-214.87,-592.80)
 .. controls (-200.10,-594.23) and (-199.92,-596.74) .. (-195.96,-601.42)
),
((-232.69,-597.66)
 -- (-243.67,-602.34)
)));
current_src := "lumio.th2 [10]";
string area_border[];
area_border[1] := "l33-654-1261";
area_border[2] := "l2-2921-5866";
area_border[3] := "l34-588-704";
area_border[4] := "l36-538-843";
area_border[5] := "l35-440-915";
area_border[6] := "l3-2689-6022";
drawoptions();
a_blocks(buildcycle(((-284.70,-525.28)
 .. controls (-284.70,-525.28) and (-280.92,-529.96) .. (-274.80,-535.73)
 .. controls (-268.69,-541.50) and (-265.81,-544.39) .. (-257.53,-542.41)
 .. controls (-249.25,-540.44) and (-251.05,-533.77) .. (-243.85,-536.66)
 .. controls (-236.65,-539.54) and (-232.51,-533.77) .. (-228.55,-540.80)
 .. controls (-224.59,-547.82) and (-226.03,-549.80) .. (-225.49,-557.18)
 .. controls (-224.95,-564.56) and (-220.27,-568.33) .. (-221.89,-577.33)
 .. controls (-223.51,-586.32) and (-243.67,-602.34) .. (-243.67,-602.34)
),
((-274.63,-633.14)
 .. controls (-273.37,-629.90) and (-275.53,-625.94) .. (-273.37,-624.32)
 .. controls (-271.21,-622.70) and (-268.15,-620.54) .. (-264.19,-616.58)
 .. controls (-260.23,-612.61) and (-258.25,-604.69) .. (-255.01,-602.53)
 .. controls (-251.77,-600.37) and (-230.89,-596.40) .. (-227.65,-596.94)
 .. controls (-224.41,-597.48) and (-214.33,-596.21) .. (-209.29,-597.65)
 .. controls (-204.24,-599.08) and (-185.70,-602.85) .. (-182.82,-600.86)
 .. controls (-179.94,-598.88) and (-179.94,-601.04) .. (-178.14,-589.89)
 .. controls (-176.34,-578.73) and (-174.90,-555.87) .. (-174.36,-551.73)
 .. controls (-173.82,-547.59) and (-172.38,-515.01) .. (-169.68,-504.76)
 .. controls (-166.98,-494.51) and (-155.65,-465.20) .. (-152.95,-459.80)
 .. controls (-150.25,-454.41) and (-136.75,-428.47) .. (-134.77,-423.97)
 .. controls (-132.79,-419.46) and (-116.41,-378.77) .. (-109.57,-369.77)
 .. controls (-102.73,-360.78) and (-102.01,-351.96) .. (-100.39,-347.28)
 .. controls (-98.77,-342.60) and (-95.53,-332.33) .. (-95.53,-328.19)
 .. controls (-95.53,-324.05) and (-95.17,-309.28) .. (-92.65,-305.68)
 .. controls (-90.13,-302.07) and (-85.45,-286.23) .. (-85.63,-279.76)
 .. controls (-85.81,-273.28) and (-81.68,-252.96) .. (-80.78,-245.59)
 .. controls (-79.88,-238.21) and (-78.08,-235.33) .. (-75.57,-230.65)
 .. controls (-73.05,-225.97) and (-62.61,-208.88) .. (-60.09,-202.75)
 .. controls (-57.57,-196.63) and (-41.17,-162.38) .. (-39.37,-155.89)
 .. controls (-37.56,-149.41) and (-28.21,-126.75) .. (-26.23,-122.43)
 .. controls (-24.25,-118.11) and (-19.57,-107.85) .. (-15.60,-101.00)
 .. controls (-11.64,-94.15) and (0.61,-78.10) .. (4.75,-67.29)
 .. controls (8.90,-56.49) and (11.23,-42.46) .. (11.77,-38.69)
 .. controls (12.31,-34.91) and (14.99,-9.24) .. (14.63,-2.95)
 .. controls (14.27,3.35) and (12.29,14.15) .. (16.62,26.60)
 .. controls (20.95,39.05) and (27.98,49.70) .. (29.06,55.28)
 .. controls (30.14,60.86) and (35.54,73.45) .. (36.44,78.13)
 .. controls (37.34,82.80) and (38.96,102.24) .. (44.01,111.62)
 .. controls (49.05,121.00) and (55.18,136.14) .. (58.96,142.25)
 .. controls (62.74,148.36) and (69.03,159.31) .. (74.07,162.37)
 .. controls (79.11,165.44) and (87.76,167.63) .. (90.64,176.08)
 .. controls (93.52,184.55) and (95.15,192.67) .. (97.67,197.19)
 .. controls (100.20,201.71) and (106.15,218.51) .. (111.74,229.52)
 .. controls (117.32,240.51) and (125.59,255.77) .. (128.64,260.43)
 .. controls (131.69,265.09) and (137.25,278.68) .. (139.94,282.08)
 .. controls (142.64,285.47) and (149.46,295.86) .. (150.90,300.72)
 .. controls (152.34,305.58) and (152.35,314.25) .. (156.50,319.70)
 .. controls (160.66,325.14) and (178.33,343.24) .. (181.03,345.40)
 .. controls (183.73,347.56) and (189.85,354.95) .. (195.24,352.76)
 .. controls (200.64,350.57) and (211.05,343.99) .. (213.02,342.53)
 .. controls (215.00,341.07) and (222.91,335.39) .. (222.91,335.39)
 .. controls (222.91,335.39) and (214.63,333.86) .. (214.46,325.79)
 .. controls (214.30,317.74) and (216.83,310.22) .. (219.36,304.13)
 .. controls (221.89,298.05) and (233.78,276.33) .. (235.94,274.17)
 .. controls (238.10,272.01) and (247.10,260.12) .. (253.75,256.14)
 .. controls (260.40,252.16) and (275.50,245.98) .. (279.82,245.24)
 .. controls (284.13,244.50) and (289.35,246.82) .. (292.04,245.18)
 .. controls (294.74,243.55) and (299.77,240.47) .. (301.93,238.84)
 .. controls (304.09,237.21) and (304.99,237.03) .. (304.09,232.18)
 .. controls (303.20,227.34) and (302.12,227.34) .. (304.82,223.56)
 .. controls (307.52,219.79) and (319.41,212.78) .. (326.42,220.13)
 .. controls (333.44,227.49) and (334.87,238.81) .. (336.13,244.03)
 .. controls (337.39,249.25) and (339.02,255.92) .. (342.08,258.45)
 .. controls (345.14,260.98) and (353.26,269.67) .. (354.70,272.93)
 .. controls (356.14,276.18) and (360.12,282.53) .. (357.24,288.48)
 .. controls (354.36,294.44) and (354.36,294.26) .. (345.35,297.83)
 .. controls (336.35,301.41) and (326.62,304.61) .. (323.73,307.47)
 .. controls (320.84,310.33) and (306.07,315.66) .. (309.14,325.07)
 .. controls (312.22,334.52) and (320.37,348.19) .. (323.26,352.93)
 .. controls (326.15,357.66) and (333.38,380.08) .. (335.36,383.69)
 .. controls (337.35,387.30) and (341.67,399.38) .. (343.12,401.74)
 .. controls (344.56,404.10) and (356.34,437.36) .. (359.40,445.43)
 .. controls (362.41,453.39) and (374.35,467.45) .. (375.93,471.66)
 .. controls (377.54,475.92) and (380.48,483.51) .. (386.30,489.88)
 .. controls (392.25,496.41) and (412.66,511.01) .. (404.82,528.57)
 .. controls (396.96,546.16) and (394.84,547.61) .. (394.36,552.37)
 .. controls (393.88,557.08) and (393.96,566.76) .. (394.34,571.36)
 .. controls (394.72,575.92) and (402.60,588.51) .. (402.80,591.14)
 .. controls (403.00,593.78) and (400.78,593.88) .. (400.71,600.13)
 .. controls (400.63,606.45) and (396.16,606.91) .. (401.08,612.71)
 .. controls (405.33,617.73) and (410.03,618.64) .. (414.01,621.43)
 .. controls (419.86,625.53) and (424.86,637.72) .. (428.52,644.21)
),
((-289.30,-648.60)
 .. controls (-289.30,-648.60) and (-286.50,-645.48) .. (-283.99,-643.93)
 .. controls (-280.21,-641.59) and (-279.31,-642.31) .. (-277.33,-640.69)
 .. controls (-275.65,-639.32) and (-274.63,-633.14) .. (-274.63,-633.14)
),
((-312.78,-603.41)
 -- (-273.37,-648.97)
),
((-296.23,-600.00)
 .. controls (-296.23,-600.00) and (-296.95,-600.72) .. (-299.11,-601.98)
 .. controls (-301.27,-603.24) and (-300.19,-605.94) .. (-305.23,-605.04)
 .. controls (-310.27,-604.13) and (-314.22,-604.13) .. (-314.22,-604.13)
),
((405.00,654.29)
 .. controls (398.81,646.81) and (396.72,647.16) .. (388.59,637.72)
 .. controls (380.42,628.24) and (374.64,616.81) .. (371.22,609.56)
 .. controls (368.46,603.72) and (364.29,596.44) .. (362.24,591.79)
 .. controls (360.15,587.03) and (357.37,575.36) .. (355.61,571.05)
 .. controls (353.82,566.64) and (344.95,541.91) .. (343.23,535.85)
 .. controls (341.52,529.77) and (335.49,523.72) .. (334.28,514.27)
 .. controls (333.08,504.87) and (332.50,500.94) .. (331.55,495.18)
 .. controls (330.61,489.46) and (327.54,485.46) .. (325.52,476.66)
 .. controls (323.49,467.87) and (321.09,457.39) .. (320.35,453.88)
 .. controls (319.60,450.37) and (311.17,432.55) .. (309.70,427.76)
 .. controls (308.24,423.00) and (304.09,416.48) .. (302.11,412.00)
 .. controls (300.15,407.54) and (295.87,397.96) .. (294.27,391.39)
 .. controls (292.67,384.79) and (287.81,379.43) .. (286.38,375.29)
 .. controls (284.94,371.15) and (277.19,360.85) .. (276.47,360.13)
 .. controls (275.74,359.40) and (275.74,355.80) .. (264.22,355.58)
 .. controls (252.68,355.37) and (244.75,354.21) .. (240.60,353.64)
 .. controls (236.45,353.07) and (228.34,354.30) .. (224.22,359.57)
 .. controls (220.09,364.84) and (210.03,373.93) .. (206.98,377.19)
 .. controls (203.93,380.45) and (199.97,387.14) .. (194.21,390.54)
 .. controls (188.44,393.94) and (179.96,401.08) .. (174.54,401.38)
 .. controls (169.13,401.68) and (160.11,403.94) .. (154.87,402.46)
 .. controls (149.65,400.99) and (141.01,386.61) .. (135.81,379.83)
 .. controls (130.61,373.06) and (131.33,365.17) .. (128.10,356.75)
 .. controls (124.87,348.30) and (117.31,338.76) .. (114.42,332.27)
 .. controls (111.54,325.78) and (96.61,309.26) .. (91.40,303.16)
 .. controls (86.18,297.06) and (75.57,293.14) .. (72.70,286.30)
 .. controls (69.82,279.45) and (67.12,278.38) .. (71.07,269.89)
 .. controls (75.03,261.41) and (77.72,250.40) .. (77.72,246.79)
 .. controls (77.71,243.18) and (75.89,225.64) .. (72.64,217.49)
 .. controls (69.39,209.34) and (60.55,192.89) .. (56.23,186.77)
 .. controls (51.91,180.65) and (42.74,174.75) .. (40.04,170.45)
 .. controls (37.35,166.15) and (26.55,153.58) .. (22.95,147.82)
 .. controls (19.35,142.05) and (13.76,130.86) .. (13.04,128.51)
 .. controls (12.32,126.16) and (7.08,112.98) .. (6.00,108.47)
 .. controls (4.92,103.97) and (4.74,103.97) .. (0.42,100.91)
 .. controls (-3.90,97.86) and (-7.86,96.25) .. (-7.86,92.65)
 .. controls (-7.85,89.06) and (-5.88,88.16) .. (-4.79,83.66)
 .. controls (-3.71,79.17) and (-0.47,76.65) .. (-1.73,70.73)
 .. controls (-2.98,64.80) and (-9.46,60.32) .. (-12.88,55.64)
 .. controls (-16.30,50.97) and (-18.28,42.86) .. (-19.18,38.18)
 .. controls (-20.08,33.50) and (-18.11,24.30) .. (-19.01,17.09)
 .. controls (-19.91,9.89) and (-22.43,5.04) .. (-23.69,0.36)
 .. controls (-24.95,-4.32) and (-25.67,-15.47) .. (-29.27,-23.56)
 .. controls (-32.87,-31.65) and (-44.57,-46.96) .. (-46.19,-51.11)
 .. controls (-47.82,-55.26) and (-55.75,-73.48) .. (-57.91,-78.71)
 .. controls (-60.07,-83.93) and (-64.40,-88.25) .. (-62.06,-94.56)
 .. controls (-59.72,-100.87) and (-55.58,-107.71) .. (-58.10,-113.28)
 .. controls (-60.61,-118.85) and (-62.95,-133.94) .. (-65.29,-143.48)
 .. controls (-67.63,-153.02) and (-71.77,-165.81) .. (-72.68,-170.31)
 .. controls (-73.58,-174.82) and (-75.20,-185.28) .. (-81.32,-190.68)
 .. controls (-87.44,-196.08) and (-98.42,-203.82) .. (-99.86,-207.96)
 .. controls (-101.30,-212.10) and (-105.80,-228.49) .. (-106.88,-231.73)
 .. controls (-107.96,-234.97) and (-118.40,-244.86) .. (-121.46,-251.51)
 .. controls (-124.51,-258.16) and (-132.79,-270.93) .. (-134.41,-277.23)
 .. controls (-136.03,-283.53) and (-138.19,-296.14) .. (-136.75,-303.71)
 .. controls (-135.31,-311.28) and (-131.18,-323.17) .. (-130.82,-328.94)
 .. controls (-130.46,-334.70) and (-130.28,-341.72) .. (-137.66,-350.72)
 .. controls (-145.03,-359.70) and (-150.07,-369.95) .. (-156.91,-379.12)
 .. controls (-163.75,-388.30) and (-170.95,-402.52) .. (-172.75,-408.29)
 .. controls (-174.55,-414.05) and (-184.99,-432.42) .. (-187.87,-437.64)
 .. controls (-190.74,-442.86) and (-205.32,-462.46) .. (-206.94,-465.34)
 .. controls (-208.56,-468.21) and (-221.34,-487.65) .. (-230.16,-495.58)
 .. controls (-238.98,-503.50) and (-250.50,-509.99) .. (-256.44,-512.15)
 .. controls (-262.38,-514.31) and (-278.40,-523.12) .. (-281.64,-531.76)
 .. controls (-284.88,-540.41) and (-286.50,-550.13) .. (-285.78,-557.33)
 .. controls (-285.06,-564.53) and (-282.73,-575.52) .. (-283.81,-581.10)
 .. controls (-284.89,-586.68) and (-285.79,-591.72) .. (-289.03,-594.42)
 .. controls (-292.27,-597.12) and (-296.23,-600.00) .. (-296.23,-600.00)
)));
ATTR__id := "l42-4197-7246";
ATTR__height := -1;
drawoptions();
l_rockborder(((374.16,570.90)
 .. controls (369.84,568.31) and (372.37,569.44) .. (371.64,569.07)
 .. controls (370.92,568.69) and (368.21,567.04) .. (365.34,563.25)
 .. controls (362.43,559.41) and (360.06,554.80) .. (358.77,551.44)
 .. controls (357.46,548.07) and (362.43,542.68) .. (364.93,541.40)
 .. controls (367.43,540.11) and (376.58,537.05) .. (379.28,536.74)
 .. controls (381.98,536.43) and (385.48,539.67) .. (387.31,541.10)
 .. controls (389.15,542.53) and (393.93,547.75) .. (394.13,548.91)
 .. controls (394.33,550.07) and (393.22,565.23) .. (392.50,566.83)
 .. controls (391.79,568.41) and (391.46,572.38) .. (389.06,575.31)
 .. controls (386.70,578.19) and (385.59,575.46) .. (381.56,576.14)
 .. controls (377.53,576.81) and (378.50,573.53) .. cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_pit(((400.95,651.14)
 .. controls (400.95,651.14) and (403.01,651.59) .. (404.88,649.30)
 .. controls (406.90,646.84) and (407.68,641.48) .. (408.12,635.41)
 .. controls (408.55,629.59) and (408.69,628.78) .. (410.39,625.55)
 .. controls (411.92,622.64) and (412.51,621.60) .. (413.96,621.41)
 .. controls (415.41,621.21) and (415.85,621.69) .. (416.44,622.17)
 .. controls (417.15,622.75) and (417.80,623.59) .. (418.69,625.45)
 .. controls (419.78,627.71) and (422.08,633.35) .. (422.08,633.35)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((314.23,431.47)
 .. controls (314.23,431.47) and (308.39,423.13) .. (317.06,417.97)
 .. controls (325.70,412.82) and (335.54,425.61) .. (335.54,425.61)
 .. controls (335.54,425.61) and (335.74,433.45) .. (330.16,437.03)
 .. controls (324.58,440.61) and (314.23,431.47) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((328.93,478.63)
 .. controls (328.93,478.63) and (333.36,465.80) .. (345.54,463.77)
 .. controls (357.71,461.74) and (366.67,460.17) .. (365.55,466.82)
 .. controls (364.42,473.52) and (353.38,481.83) .. (350.71,482.86)
 .. controls (348.05,483.89) and (334.93,492.87) .. (331.85,488.14)
 .. controls (326.05,479.21) and (328.93,478.63) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((343.39,463.99)
 .. controls (343.39,463.99) and (336.35,450.08) .. (346.26,445.24)
 .. controls (356.16,440.40) and (357.94,452.36) .. (357.73,456.96)
 .. controls (357.43,463.83) and (343.39,463.99) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((320.87,452.04)
 .. controls (320.87,452.04) and (326.96,446.19) .. (332.03,447.88)
 .. controls (337.08,449.57) and (338.17,457.18) .. (329.04,463.07)
 .. controls (319.89,468.97) and (320.87,452.04) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((336.11,516.51)
 .. controls (337.73,517.06) and (339.89,518.17) .. (341.11,515.68)
 .. controls (342.32,513.18) and (343.02,512.02) .. (344.76,509.12)
 .. controls (346.50,506.22) and (348.56,500.83) .. (348.54,499.32)
 .. controls (348.52,497.81) and (349.56,495.14) .. (345.66,496.23)
 .. controls (341.75,497.32) and (341.21,497.14) .. (339.27,498.70)
 .. controls (337.32,500.26) and (335.73,501.80) .. (335.06,505.20)
 .. controls (334.38,508.60) and (334.48,515.96) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((360.74,512.43)
 .. controls (357.21,515.21) and (358.05,512.28) .. (355.91,512.71)
 .. controls (353.77,513.14) and (353.18,510.45) .. (352.24,507.97)
 .. controls (351.31,505.50) and (353.41,503.33) .. (354.79,499.85)
 .. controls (356.16,496.37) and (355.98,496.38) .. (358.83,495.70)
 .. controls (361.67,495.03) and (362.58,495.38) .. (364.57,497.82)
 .. controls (366.59,500.27) and (366.25,501.83) .. (365.97,505.72)
 .. controls (365.69,509.64) and (364.26,509.65) .. cycle
));
ATTR__id := "l87-3932-6480";
ATTR__height := -1;
drawoptions();
l_border_invisible(((348.72,379.50)
 .. controls (334.43,404.80) and (289.04,401.07) .. (289.04,401.07)
));
ATTR__id := "l88-4018-6279";
ATTR__height := -1;
drawoptions();
l_border_invisible(((348.72,379.50)
 -- (323.37,322.07)
 -- (365.89,288.18)
 -- (336.67,236.29)
));
ATTR__id := "l90-3627-5642";
ATTR__height := -1;
drawoptions();
l_border_invisible(((286.65,242.69)
 -- (237.02,251.86)
 -- (214.30,314.16)
));
ATTR__id := "l91-3545-6308";
ATTR__height := -1;
drawoptions();
l_border_invisible(((246.92,356.40)
 -- (289.04,401.07)
));
ATTR__id := "l93-3770-5546";
ATTR__height := -1;
drawoptions();
l_border_invisible(((286.65,242.69)
 -- (308.79,209.57)
 -- (337.76,220.32)
 -- (336.67,236.29)
));
ATTR__id := "l99-4135-6955";
ATTR__height := -1;
drawoptions();
l_border_invisible(((297.27,418.37)
 -- (349.26,399.15)
 -- (368.03,447.38)
 -- (322.83,477.25)
 -- cycle
));
ATTR__id := "l38-3808-5660";
ATTR__height := -1;
drawoptions();
l_pit(((336.67,236.29)
 .. controls (336.67,236.29) and (331.45,237.54) .. (328.57,237.90)
 .. controls (325.68,238.26) and (322.26,240.06) .. (319.92,240.24)
 .. controls (317.58,240.42) and (316.68,242.04) .. (317.22,245.46)
 .. controls (317.77,248.88) and (320.28,247.08) .. (319.21,252.13)
 .. controls (318.13,257.18) and (318.85,256.10) .. (318.13,256.64)
 .. controls (317.41,257.18) and (315.61,255.92) .. (313.45,254.66)
 .. controls (311.29,253.40) and (302.29,248.56) .. (299.96,247.85)
 .. controls (297.62,247.14) and (288.81,243.76) .. (286.65,242.69)
));
ATTR__id := "l37-4253-7640";
ATTR__height := -1;
drawoptions();
l_pit(((370.85,610.42)
 .. controls (371.20,609.84) and (373.12,608.52) .. (373.80,608.30)
 .. controls (374.47,608.08) and (378.32,607.01) .. (380.31,607.60)
 .. controls (382.37,608.21) and (383.37,607.87) .. (384.66,607.52)
 .. controls (385.93,607.18) and (387.72,608.56) .. (389.07,609.57)
 .. controls (390.42,610.57) and (391.19,611.68) .. (393.25,611.36)
 .. controls (395.28,611.03) and (397.07,610.38) .. (398.30,611.21)
 .. controls (399.50,612.02) and (399.49,614.42) .. (401.12,615.36)
 .. controls (402.68,616.25) and (402.75,616.65) .. (404.30,617.10)
 .. controls (405.83,617.53) and (406.78,616.96) .. (406.78,616.96)
));
ATTR__id := "l110-4061-7415";
ATTR__height := -1;
drawoptions();
l_border_invisible(((370.85,610.42)
 -- (332.23,533.56)
));
ATTR__id := "l116-4365-7440";
ATTR__height := -1;
drawoptions();
l_border_invisible(((332.23,533.56)
 .. controls (332.23,533.56) and (327.21,512.63) .. (355.52,520.28)
 .. controls (384.28,528.06) and (371.43,470.81) .. (410.66,497.08)
 .. controls (438.60,515.78) and (399.06,552.04) .. (399.06,552.04)
 .. controls (399.06,552.04) and (383.55,533.53) .. (375.45,534.69)
 .. controls (368.18,535.72) and (344.16,547.13) .. (367.68,567.72)
 .. controls (384.35,582.32) and (388.76,580.58) .. (396.31,566.39)
 .. controls (402.71,554.38) and (411.32,607.50) .. (411.32,607.50)
 -- (406.78,616.96)
));
ATTR__id := "l77-3294-6130";
ATTR__height := -1;
drawoptions();
l_border_invisible(((222.91,335.39)
 -- (175.25,329.16)
 -- (155.77,297.68)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((58.96,142.25)
 .. controls (58.96,142.25) and (51.39,149.79) .. (60.03,157.86)
 .. controls (68.66,165.94) and (71.72,169.72) .. (77.13,164.35)
));
ATTR__id := "l74-2967-6501";
ATTR__height := -1;
drawoptions();
l_flowstone(((198.72,392.01)
 .. controls (199.61,388.04) and (194.55,386.76) .. (190.06,390.15)
 .. controls (182.49,395.87) and (178.87,397.44) .. (168.40,398.59)
 .. controls (159.10,399.62) and (146.41,400.64) .. (146.41,400.64)
));
ATTR__id := "l80-2903-6467";
ATTR__height := -1;
drawoptions();
l_border_invisible(((116.77,341.65)
 -- (130.23,385.06)
 -- (146.41,400.64)
));
ATTR__id := "l76-3250-6435";
ATTR__height := -1;
drawoptions();
l_border_invisible(((237.72,354.53)
 -- (198.72,392.01)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-172.57,-431.35)
 .. controls (-172.57,-431.35) and (-172.93,-445.40) .. (-167.71,-440.54)
 .. controls (-162.49,-435.68) and (-164.83,-431.72) .. (-164.83,-432.98)
 .. controls (-164.83,-434.24) and (-167.53,-423.43) .. (-171.85,-428.11)
 .. controls (-172.46,-428.77) and (-172.57,-431.35) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-54.85,-74.38)
 .. controls (-54.85,-74.38) and (-48.56,-93.86) .. (-34.15,-94.38)
 .. controls (-19.75,-94.90) and (-26.23,-77.79) .. (-30.36,-74.55)
 .. controls (-34.51,-71.31) and (-39.00,-65.90) .. (-51.79,-68.25)
 .. controls (-56.04,-69.03) and (-54.85,-74.38) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-46.19,-51.11)
 .. controls (-46.19,-51.11) and (-51.78,-61.21) .. (-45.12,-62.47)
 .. controls (-38.46,-63.74) and (-36.48,-59.04) .. (-37.01,-53.81)
 .. controls (-37.55,-48.58) and (-38.09,-39.93) .. (-42.95,-46.06)
 .. controls (-47.81,-52.19) and (-46.19,-51.11) .. cycle
));
ATTR__height := -1;
drawoptions();
l_floorstep(((13.04,128.51)
 .. controls (25.46,130.51) and (49.23,121.72) .. (49.23,121.72)
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-293.13,-612.88)
 .. controls (-293.13,-612.88) and (-289.17,-618.15) .. (-289.12,-618.42)
 .. controls (-289.08,-618.69) and (-286.24,-630.03) .. (-286.24,-630.44)
 .. controls (-286.24,-630.84) and (-287.68,-631.92) .. (-287.68,-631.92)
 .. controls (-287.68,-631.92) and (-290.43,-630.30) .. (-290.52,-630.07)
 .. controls (-290.61,-629.85) and (-294.12,-621.57) .. (-294.12,-621.57)
 .. controls (-294.12,-621.57) and (-293.35,-619.54) .. (-293.35,-619.09)
 .. controls (-293.35,-618.64) and (-293.13,-612.88) .. cycle
));
ATTR__id := "l30-3433-6204";
ATTR__height := -1;
drawoptions();
l_pit(((237.72,354.53)
 .. controls (237.72,354.53) and (237.17,352.53) .. (236.08,349.80)
 .. controls (235.00,347.07) and (234.27,346.34) .. (233.55,345.07)
 .. controls (232.83,343.80) and (232.11,343.97) .. (230.12,342.15)
 .. controls (228.14,340.34) and (222.91,335.39) .. (222.91,335.39)
));
ATTR__id := "l29-3492-6199";
ATTR__height := -1;
drawoptions();
l_pit(((246.92,356.40)
 .. controls (246.92,356.40) and (247.99,354.42) .. (247.45,351.88)
 .. controls (246.90,349.34) and (245.64,346.61) .. (245.63,344.44)
 .. controls (245.63,342.27) and (245.09,338.12) .. (243.46,338.10)
 .. controls (241.84,338.09) and (238.23,338.06) .. (238.23,334.99)
 .. controls (238.23,331.94) and (238.77,328.89) .. (237.51,327.80)
 .. controls (236.25,326.72) and (234.27,325.27) .. (233.37,325.09)
 .. controls (232.47,324.90) and (230.13,324.18) .. (230.13,324.18)
 .. controls (230.13,324.18) and (230.67,319.53) .. (230.14,317.74)
 .. controls (229.60,315.95) and (227.81,311.12) .. (224.75,310.58)
 .. controls (221.69,310.04) and (214.30,314.16) .. (214.30,314.16)
));
ATTR__id := "l28-2822-5750";
ATTR__height := -1;
drawoptions();
l_border_invisible(((87.26,305.52)
 .. controls (87.26,305.52) and (89.96,303.89) .. (91.04,296.50)
 .. controls (92.12,289.11) and (96.25,285.32) .. (93.92,277.77)
 .. controls (91.58,270.22) and (91.04,256.71) .. (96.98,257.61)
 .. controls (102.92,258.50) and (114.07,262.97) .. (119.64,264.39)
 .. controls (125.22,265.82) and (137.81,267.41) .. (137.81,267.41)
));
ATTR__id := "l29-2876-6009";
ATTR__height := -1;
drawoptions();
l_border_invisible(((116.77,341.65)
 .. controls (116.77,341.65) and (121.80,340.36) .. (131.88,339.62)
 .. controls (141.95,338.88) and (145.56,342.13) .. (145.01,335.44)
 .. controls (144.46,328.74) and (145.89,324.03) .. (140.48,321.68)
 .. controls (135.08,319.33) and (131.49,321.70) .. (132.56,317.18)
 .. controls (133.63,312.65) and (135.78,309.39) .. (137.94,306.31)
 .. controls (140.10,303.24) and (141.00,304.50) .. (143.16,303.23)
 .. controls (145.32,301.97) and (155.77,297.68) .. (155.77,297.68)
));
ATTR__id := "l33-654-1261";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-284.70,-525.28)
 .. controls (-284.70,-525.28) and (-280.92,-529.96) .. (-274.80,-535.73)
 .. controls (-268.69,-541.50) and (-265.81,-544.39) .. (-257.53,-542.41)
 .. controls (-249.25,-540.44) and (-251.05,-533.77) .. (-243.85,-536.66)
 .. controls (-236.65,-539.54) and (-232.51,-533.77) .. (-228.55,-540.80)
 .. controls (-224.59,-547.82) and (-226.03,-549.80) .. (-225.49,-557.18)
 .. controls (-224.95,-564.56) and (-220.27,-568.33) .. (-221.89,-577.33)
 .. controls (-223.51,-586.32) and (-243.67,-602.34) .. (-243.67,-602.34)
));
ATTR__id := "l50-1016-961";
ATTR__height := -1;
drawoptions();
l_flowstone(((-232.69,-597.66)
 .. controls (-232.69,-597.66) and (-229.63,-591.36) .. (-214.87,-592.80)
 .. controls (-200.10,-594.23) and (-199.92,-596.74) .. (-195.96,-601.42)
));
ATTR__id := "l51-1555-2955";
ATTR__height := -1;
drawoptions();
l_flowstone(((-80.24,-190.68)
 .. controls (-76.29,-191.95) and (-65.31,-201.32) .. (-66.57,-207.98)
 .. controls (-67.83,-214.64) and (-69.09,-210.50) .. (-82.05,-231.19)
 .. controls (-95.00,-251.89) and (-107.96,-233.17) .. (-107.96,-233.17)
));
ATTR__id := "l59-1721-3241";
ATTR__height := -1;
drawoptions();
l_floorstep(((-79.34,-188.52)
 .. controls (-79.34,-188.52) and (-53.24,-184.91) .. (-70.69,-164.01)
));
ATTR__id := "l61-1915-4187";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-56.27,-49.48)
 .. controls (-56.27,-49.48) and (9.59,-5.64) .. (27.25,-23.77)
));
ATTR__id := "l63-2243-4056";
ATTR__height := -1;
drawoptions();
l_border_invisible(((27.25,-23.77)
 -- (-23.88,-158.76)
 -- (-68.72,-255.29)
 -- (-92.65,-352.31)
 -- (-132.79,-455.12)
 -- (-157.08,-520.95)
 -- (-173.46,-605.17)
 -- (-189.12,-606.81)
 -- (-195.96,-601.42)
));
ATTR__id := "l64-630-1464";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-284.70,-525.28)
 -- (-164.83,-376.42)
 -- (-136.93,-265.17)
 -- (-107.96,-233.17)
));
ATTR__id := "l65-1675-3232";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-80.24,-190.68)
 .. controls (-80.24,-190.68) and (-91.04,-185.63) .. (-79.34,-188.52)
));
ATTR__id := "l66-1738-3654";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-70.69,-164.01)
 .. controls (-70.69,-164.01) and (-74.29,-93.10) .. (-60.61,-74.01)
));
ATTR__id := "l67-806-946";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-232.69,-597.66)
 -- (-243.67,-602.34)
));
ATTR__id := "l62-1845-4063";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-56.27,-49.48)
 -- (-60.61,-74.01)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((-80.24,-190.68)
 .. controls (-61.17,-211.22) and (-92.30,-219.49) .. (-92.84,-228.50)
 .. controls (-93.39,-237.50) and (-98.60,-240.73) .. (-98.60,-240.73)
));
ATTR__id := "l36-538-843";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-312.78,-603.41)
 -- (-273.37,-648.97)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-284.67,-622.83)
 .. controls (-285.21,-622.79) and (-285.93,-622.92) .. (-286.20,-622.97)
 .. controls (-286.47,-623.01) and (-286.83,-625.85) .. (-286.92,-626.16)
 .. controls (-287.01,-626.48) and (-286.29,-629.09) .. (-286.15,-629.67)
 .. controls (-286.02,-630.26) and (-283.00,-636.20) .. (-282.51,-636.60)
 .. controls (-282.01,-637.01) and (-278.28,-639.12) .. (-277.65,-638.99)
 .. controls (-277.02,-638.85) and (-276.36,-637.21) .. (-276.07,-636.33)
 .. controls (-275.71,-635.21) and (-275.13,-633.99) .. (-274.59,-632.19)
 .. controls (-274.13,-630.68) and (-274.45,-628.19) .. (-274.59,-627.92)
 .. controls (-274.72,-627.65) and (-274.68,-625.67) .. (-274.90,-625.00)
 .. controls (-275.13,-624.32) and (-276.66,-623.24) .. (-278.19,-622.66)
 .. controls (-279.72,-622.07) and (-280.57,-622.34) .. (-281.47,-622.38)
 .. controls (-282.37,-622.43) and (-284.13,-622.88) .. cycle
));
ATTR__height := -1;
drawoptions();
l_rockborder(((-301.04,-604.50)
 .. controls (-301.04,-604.50) and (-294.57,-608.47) .. (-294.07,-609.28)
 .. controls (-293.58,-610.09) and (-292.99,-611.94) .. (-293.13,-612.88)
 .. controls (-293.26,-613.83) and (-293.22,-618.51) .. (-293.44,-619.41)
 .. controls (-293.67,-620.31) and (-294.43,-623.14) .. (-295.56,-622.02)
 .. controls (-296.68,-620.89) and (-300.50,-616.48) .. (-300.50,-616.48)
 .. controls (-300.50,-616.48) and (-302.48,-607.47) .. (-302.44,-606.84)
 .. controls (-302.39,-606.21) and (-302.26,-605.13) .. (-302.26,-605.13)
 -- cycle
));
endfig;
beginfig(33);
draw_upscrap(1)(1,((-274.63,-633.14)
 .. controls (-273.37,-629.90) and (-275.53,-625.94) .. (-273.37,-624.32)
 .. controls (-271.21,-622.70) and (-268.15,-620.54) .. (-264.19,-616.58)
 .. controls (-260.23,-612.61) and (-258.25,-604.69) .. (-255.01,-602.53)
 .. controls (-251.77,-600.37) and (-230.89,-596.40) .. (-227.65,-596.94)
 .. controls (-224.41,-597.48) and (-214.33,-596.21) .. (-209.29,-597.65)
 .. controls (-204.24,-599.08) and (-185.70,-602.85) .. (-182.82,-600.86)
 .. controls (-179.94,-598.88) and (-179.94,-601.04) .. (-178.14,-589.89)
 .. controls (-176.34,-578.73) and (-174.90,-555.87) .. (-174.36,-551.73)
 .. controls (-173.82,-547.59) and (-172.38,-515.01) .. (-169.68,-504.76)
 .. controls (-166.98,-494.51) and (-155.65,-465.20) .. (-152.95,-459.80)
 .. controls (-150.25,-454.41) and (-136.75,-428.47) .. (-134.77,-423.97)
 .. controls (-132.79,-419.46) and (-116.41,-378.77) .. (-109.57,-369.77)
 .. controls (-102.73,-360.78) and (-102.01,-351.96) .. (-100.39,-347.28)
 .. controls (-98.77,-342.60) and (-95.53,-332.33) .. (-95.53,-328.19)
 .. controls (-95.53,-324.05) and (-95.17,-309.28) .. (-92.65,-305.68)
 .. controls (-90.13,-302.07) and (-85.45,-286.23) .. (-85.63,-279.76)
 .. controls (-85.81,-273.28) and (-81.68,-252.96) .. (-80.78,-245.59)
 .. controls (-79.88,-238.21) and (-78.08,-235.33) .. (-75.57,-230.65)
 .. controls (-73.05,-225.97) and (-62.61,-208.88) .. (-60.09,-202.75)
 .. controls (-57.57,-196.63) and (-41.17,-162.38) .. (-39.37,-155.89)
 .. controls (-37.56,-149.41) and (-28.21,-126.75) .. (-26.23,-122.43)
 .. controls (-24.25,-118.11) and (-19.57,-107.85) .. (-15.60,-101.00)
 .. controls (-11.64,-94.15) and (0.61,-78.10) .. (4.75,-67.29)
 .. controls (8.90,-56.49) and (11.23,-42.46) .. (11.77,-38.69)
 .. controls (12.31,-34.91) and (14.99,-9.24) .. (14.63,-2.95)
 .. controls (14.27,3.35) and (12.29,14.15) .. (16.62,26.60)
 .. controls (20.95,39.05) and (27.98,49.70) .. (29.06,55.28)
 .. controls (30.14,60.86) and (35.54,73.45) .. (36.44,78.13)
 .. controls (37.34,82.80) and (38.96,102.24) .. (44.01,111.62)
 .. controls (49.05,121.00) and (55.18,136.14) .. (58.96,142.25)
 .. controls (62.74,148.36) and (69.03,159.31) .. (74.07,162.37)
 .. controls (79.11,165.44) and (87.76,167.63) .. (90.64,176.08)
 .. controls (93.52,184.55) and (95.15,192.67) .. (97.67,197.19)
 .. controls (100.20,201.71) and (106.15,218.51) .. (111.74,229.52)
 .. controls (117.32,240.51) and (125.59,255.77) .. (128.64,260.43)
 .. controls (131.69,265.09) and (137.25,278.68) .. (139.94,282.08)
 .. controls (142.64,285.47) and (149.46,295.86) .. (150.90,300.72)
 .. controls (152.34,305.58) and (152.35,314.25) .. (156.50,319.70)
 .. controls (160.66,325.14) and (178.33,343.24) .. (181.03,345.40)
 .. controls (183.73,347.56) and (189.85,354.95) .. (195.24,352.76)
 .. controls (200.64,350.57) and (211.05,343.99) .. (213.02,342.53)
 .. controls (215.00,341.07) and (222.91,335.39) .. (222.91,335.39)
 .. controls (222.91,335.39) and (214.63,333.86) .. (214.46,325.79)
 .. controls (214.30,317.74) and (216.83,310.22) .. (219.36,304.13)
 .. controls (221.89,298.05) and (233.78,276.33) .. (235.94,274.17)
 .. controls (238.10,272.01) and (247.10,260.12) .. (253.75,256.14)
 .. controls (260.40,252.16) and (275.50,245.98) .. (279.82,245.24)
 .. controls (284.13,244.50) and (289.35,246.82) .. (292.04,245.18)
 .. controls (294.74,243.55) and (299.77,240.47) .. (301.93,238.84)
 .. controls (304.09,237.21) and (304.99,237.03) .. (304.09,232.18)
 .. controls (303.20,227.34) and (302.12,227.34) .. (304.82,223.56)
 .. controls (307.52,219.79) and (319.41,212.78) .. (326.42,220.13)
 .. controls (333.44,227.49) and (334.87,238.81) .. (336.13,244.03)
 .. controls (337.39,249.25) and (339.02,255.92) .. (342.08,258.45)
 .. controls (345.14,260.98) and (353.26,269.67) .. (354.70,272.93)
 .. controls (356.14,276.18) and (360.12,282.53) .. (357.24,288.48)
 .. controls (354.36,294.44) and (354.36,294.26) .. (345.35,297.83)
 .. controls (336.35,301.41) and (326.62,304.61) .. (323.73,307.47)
 .. controls (320.84,310.33) and (306.07,315.66) .. (309.14,325.07)
 .. controls (312.22,334.52) and (320.37,348.19) .. (323.26,352.93)
 .. controls (326.15,357.66) and (333.38,380.08) .. (335.36,383.69)
 .. controls (337.35,387.30) and (341.67,399.38) .. (343.12,401.74)
 .. controls (344.56,404.10) and (356.34,437.36) .. (359.40,445.43)
 .. controls (362.41,453.39) and (374.35,467.45) .. (375.93,471.66)
 .. controls (377.54,475.92) and (380.48,483.51) .. (386.30,489.88)
 .. controls (392.25,496.41) and (412.66,511.01) .. (404.82,528.57)
 .. controls (396.96,546.16) and (394.84,547.61) .. (394.36,552.37)
 .. controls (393.88,557.08) and (393.96,566.76) .. (394.34,571.36)
 .. controls (394.72,575.92) and (402.60,588.51) .. (402.80,591.14)
 .. controls (403.00,593.78) and (400.78,593.88) .. (400.71,600.13)
 .. controls (400.63,606.45) and (396.16,606.91) .. (401.08,612.71)
 .. controls (405.33,617.73) and (410.03,618.64) .. (414.01,621.43)
 .. controls (419.86,625.53) and (424.86,637.72) .. (428.52,644.21)
),
1,((405.00,654.29)
 .. controls (398.81,646.81) and (396.72,647.16) .. (388.59,637.72)
 .. controls (380.42,628.24) and (374.64,616.81) .. (371.22,609.56)
 .. controls (368.46,603.72) and (364.29,596.44) .. (362.24,591.79)
 .. controls (360.15,587.03) and (357.37,575.36) .. (355.61,571.05)
 .. controls (353.82,566.64) and (344.95,541.91) .. (343.23,535.85)
 .. controls (341.52,529.77) and (335.49,523.72) .. (334.28,514.27)
 .. controls (333.08,504.87) and (332.50,500.94) .. (331.55,495.18)
 .. controls (330.61,489.46) and (327.54,485.46) .. (325.52,476.66)
 .. controls (323.49,467.87) and (321.09,457.39) .. (320.35,453.88)
 .. controls (319.60,450.37) and (311.17,432.55) .. (309.70,427.76)
 .. controls (308.24,423.00) and (304.09,416.48) .. (302.11,412.00)
 .. controls (300.15,407.54) and (295.87,397.96) .. (294.27,391.39)
 .. controls (292.67,384.79) and (287.81,379.43) .. (286.38,375.29)
 .. controls (284.94,371.15) and (277.19,360.85) .. (276.47,360.13)
 .. controls (275.74,359.40) and (275.74,355.80) .. (264.22,355.58)
 .. controls (252.68,355.37) and (244.75,354.21) .. (240.60,353.64)
 .. controls (236.45,353.07) and (228.34,354.30) .. (224.22,359.57)
 .. controls (220.09,364.84) and (210.03,373.93) .. (206.98,377.19)
 .. controls (203.93,380.45) and (199.97,387.14) .. (194.21,390.54)
 .. controls (188.44,393.94) and (179.96,401.08) .. (174.54,401.38)
 .. controls (169.13,401.68) and (160.11,403.94) .. (154.87,402.46)
 .. controls (149.65,400.99) and (141.01,386.61) .. (135.81,379.83)
 .. controls (130.61,373.06) and (131.33,365.17) .. (128.10,356.75)
 .. controls (124.87,348.30) and (117.31,338.76) .. (114.42,332.27)
 .. controls (111.54,325.78) and (96.61,309.26) .. (91.40,303.16)
 .. controls (86.18,297.06) and (75.57,293.14) .. (72.70,286.30)
 .. controls (69.82,279.45) and (67.12,278.38) .. (71.07,269.89)
 .. controls (75.03,261.41) and (77.72,250.40) .. (77.72,246.79)
 .. controls (77.71,243.18) and (75.89,225.64) .. (72.64,217.49)
 .. controls (69.39,209.34) and (60.55,192.89) .. (56.23,186.77)
 .. controls (51.91,180.65) and (42.74,174.75) .. (40.04,170.45)
 .. controls (37.35,166.15) and (26.55,153.58) .. (22.95,147.82)
 .. controls (19.35,142.05) and (13.76,130.86) .. (13.04,128.51)
 .. controls (12.32,126.16) and (7.08,112.98) .. (6.00,108.47)
 .. controls (4.92,103.97) and (4.74,103.97) .. (0.42,100.91)
 .. controls (-3.90,97.86) and (-7.86,96.25) .. (-7.86,92.65)
 .. controls (-7.85,89.06) and (-5.88,88.16) .. (-4.79,83.66)
 .. controls (-3.71,79.17) and (-0.47,76.65) .. (-1.73,70.73)
 .. controls (-2.98,64.80) and (-9.46,60.32) .. (-12.88,55.64)
 .. controls (-16.30,50.97) and (-18.28,42.86) .. (-19.18,38.18)
 .. controls (-20.08,33.50) and (-18.11,24.30) .. (-19.01,17.09)
 .. controls (-19.91,9.89) and (-22.43,5.04) .. (-23.69,0.36)
 .. controls (-24.95,-4.32) and (-25.67,-15.47) .. (-29.27,-23.56)
 .. controls (-32.87,-31.65) and (-44.57,-46.96) .. (-46.19,-51.11)
 .. controls (-47.82,-55.26) and (-55.75,-73.48) .. (-57.91,-78.71)
 .. controls (-60.07,-83.93) and (-64.40,-88.25) .. (-62.06,-94.56)
 .. controls (-59.72,-100.87) and (-55.58,-107.71) .. (-58.10,-113.28)
 .. controls (-60.61,-118.85) and (-62.95,-133.94) .. (-65.29,-143.48)
 .. controls (-67.63,-153.02) and (-71.77,-165.81) .. (-72.68,-170.31)
 .. controls (-73.58,-174.82) and (-75.20,-185.28) .. (-81.32,-190.68)
 .. controls (-87.44,-196.08) and (-98.42,-203.82) .. (-99.86,-207.96)
 .. controls (-101.30,-212.10) and (-105.80,-228.49) .. (-106.88,-231.73)
 .. controls (-107.96,-234.97) and (-118.40,-244.86) .. (-121.46,-251.51)
 .. controls (-124.51,-258.16) and (-132.79,-270.93) .. (-134.41,-277.23)
 .. controls (-136.03,-283.53) and (-138.19,-296.14) .. (-136.75,-303.71)
 .. controls (-135.31,-311.28) and (-131.18,-323.17) .. (-130.82,-328.94)
 .. controls (-130.46,-334.70) and (-130.28,-341.72) .. (-137.66,-350.72)
 .. controls (-145.03,-359.70) and (-150.07,-369.95) .. (-156.91,-379.12)
 .. controls (-163.75,-388.30) and (-170.95,-402.52) .. (-172.75,-408.29)
 .. controls (-174.55,-414.05) and (-184.99,-432.42) .. (-187.87,-437.64)
 .. controls (-190.74,-442.86) and (-205.32,-462.46) .. (-206.94,-465.34)
 .. controls (-208.56,-468.21) and (-221.34,-487.65) .. (-230.16,-495.58)
 .. controls (-238.98,-503.50) and (-250.50,-509.99) .. (-256.44,-512.15)
 .. controls (-262.38,-514.31) and (-278.40,-523.12) .. (-281.64,-531.76)
 .. controls (-284.88,-540.41) and (-286.50,-550.13) .. (-285.78,-557.33)
 .. controls (-285.06,-564.53) and (-282.73,-575.52) .. (-283.81,-581.10)
 .. controls (-284.89,-586.68) and (-285.79,-591.72) .. (-289.03,-594.42)
 .. controls (-292.27,-597.12) and (-296.23,-600.00) .. (-296.23,-600.00)
),
1,((-296.23,-600.00)
 .. controls (-296.23,-600.00) and (-296.95,-600.72) .. (-299.11,-601.98)
 .. controls (-301.27,-603.24) and (-300.19,-605.94) .. (-305.23,-605.04)
 .. controls (-310.27,-604.13) and (-314.22,-604.13) .. (-314.22,-604.13)
),
1,((-314.22,-604.13)
 .. controls (-314.22,-604.13) and (-316.92,-603.59) .. (-320.88,-610.78)
),
1,((-289.30,-648.60)
 .. controls (-289.30,-648.60) and (-286.50,-645.48) .. (-283.99,-643.93)
 .. controls (-280.21,-641.59) and (-279.31,-642.31) .. (-277.33,-640.69)
 .. controls (-275.65,-639.32) and (-274.63,-633.14) .. (-274.63,-633.14)
));
draw_downscrap;
endfig;
beginfig(34);
drawoptions();
p_gradient((319.80,426.02),346.0,2.00,(0,0));
drawoptions();
p_gradient((341.32,421.55),346.0,2.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-314.22,-604.13)
 .. controls (-314.22,-604.13) and (-316.92,-603.59) .. (-320.88,-610.78)
));
drawoptions();
p_entrance((-315.67,-637.61),308.6,2.00,(0,0));
ATTR__id := "l3-2689-6022";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((405.00,654.29)
 .. controls (398.81,646.81) and (396.72,647.16) .. (388.59,637.72)
 .. controls (380.42,628.24) and (374.64,616.81) .. (371.22,609.56)
 .. controls (368.46,603.72) and (364.29,596.44) .. (362.24,591.79)
 .. controls (360.15,587.03) and (357.37,575.36) .. (355.61,571.05)
 .. controls (353.82,566.64) and (344.95,541.91) .. (343.23,535.85)
 .. controls (341.52,529.77) and (335.49,523.72) .. (334.28,514.27)
 .. controls (333.08,504.87) and (332.50,500.94) .. (331.55,495.18)
 .. controls (330.61,489.46) and (327.54,485.46) .. (325.52,476.66)
 .. controls (323.49,467.87) and (321.09,457.39) .. (320.35,453.88)
 .. controls (319.60,450.37) and (311.17,432.55) .. (309.70,427.76)
 .. controls (308.24,423.00) and (304.09,416.48) .. (302.11,412.00)
 .. controls (300.15,407.54) and (295.87,397.96) .. (294.27,391.39)
 .. controls (292.67,384.79) and (287.81,379.43) .. (286.38,375.29)
 .. controls (284.94,371.15) and (277.19,360.85) .. (276.47,360.13)
 .. controls (275.74,359.40) and (275.74,355.80) .. (264.22,355.58)
 .. controls (252.68,355.37) and (244.75,354.21) .. (240.60,353.64)
 .. controls (236.45,353.07) and (228.34,354.30) .. (224.22,359.57)
 .. controls (220.09,364.84) and (210.03,373.93) .. (206.98,377.19)
 .. controls (203.93,380.45) and (199.97,387.14) .. (194.21,390.54)
 .. controls (188.44,393.94) and (179.96,401.08) .. (174.54,401.38)
 .. controls (169.13,401.68) and (160.11,403.94) .. (154.87,402.46)
 .. controls (149.65,400.99) and (141.01,386.61) .. (135.81,379.83)
 .. controls (130.61,373.06) and (131.33,365.17) .. (128.10,356.75)
 .. controls (124.87,348.30) and (117.31,338.76) .. (114.42,332.27)
 .. controls (111.54,325.78) and (96.61,309.26) .. (91.40,303.16)
 .. controls (86.18,297.06) and (75.57,293.14) .. (72.70,286.30)
 .. controls (69.82,279.45) and (67.12,278.38) .. (71.07,269.89)
 .. controls (75.03,261.41) and (77.72,250.40) .. (77.72,246.79)
 .. controls (77.71,243.18) and (75.89,225.64) .. (72.64,217.49)
 .. controls (69.39,209.34) and (60.55,192.89) .. (56.23,186.77)
 .. controls (51.91,180.65) and (42.74,174.75) .. (40.04,170.45)
 .. controls (37.35,166.15) and (26.55,153.58) .. (22.95,147.82)
 .. controls (19.35,142.05) and (13.76,130.86) .. (13.04,128.51)
 .. controls (12.32,126.16) and (7.08,112.98) .. (6.00,108.47)
 .. controls (4.92,103.97) and (4.74,103.97) .. (0.42,100.91)
 .. controls (-3.90,97.86) and (-7.86,96.25) .. (-7.86,92.65)
 .. controls (-7.85,89.06) and (-5.88,88.16) .. (-4.79,83.66)
 .. controls (-3.71,79.17) and (-0.47,76.65) .. (-1.73,70.73)
 .. controls (-2.98,64.80) and (-9.46,60.32) .. (-12.88,55.64)
 .. controls (-16.30,50.97) and (-18.28,42.86) .. (-19.18,38.18)
 .. controls (-20.08,33.50) and (-18.11,24.30) .. (-19.01,17.09)
 .. controls (-19.91,9.89) and (-22.43,5.04) .. (-23.69,0.36)
 .. controls (-24.95,-4.32) and (-25.67,-15.47) .. (-29.27,-23.56)
 .. controls (-32.87,-31.65) and (-44.57,-46.96) .. (-46.19,-51.11)
 .. controls (-47.82,-55.26) and (-55.75,-73.48) .. (-57.91,-78.71)
 .. controls (-60.07,-83.93) and (-64.40,-88.25) .. (-62.06,-94.56)
 .. controls (-59.72,-100.87) and (-55.58,-107.71) .. (-58.10,-113.28)
 .. controls (-60.61,-118.85) and (-62.95,-133.94) .. (-65.29,-143.48)
 .. controls (-67.63,-153.02) and (-71.77,-165.81) .. (-72.68,-170.31)
 .. controls (-73.58,-174.82) and (-75.20,-185.28) .. (-81.32,-190.68)
 .. controls (-87.44,-196.08) and (-98.42,-203.82) .. (-99.86,-207.96)
 .. controls (-101.30,-212.10) and (-105.80,-228.49) .. (-106.88,-231.73)
 .. controls (-107.96,-234.97) and (-118.40,-244.86) .. (-121.46,-251.51)
 .. controls (-124.51,-258.16) and (-132.79,-270.93) .. (-134.41,-277.23)
 .. controls (-136.03,-283.53) and (-138.19,-296.14) .. (-136.75,-303.71)
 .. controls (-135.31,-311.28) and (-131.18,-323.17) .. (-130.82,-328.94)
 .. controls (-130.46,-334.70) and (-130.28,-341.72) .. (-137.66,-350.72)
 .. controls (-145.03,-359.70) and (-150.07,-369.95) .. (-156.91,-379.12)
 .. controls (-163.75,-388.30) and (-170.95,-402.52) .. (-172.75,-408.29)
 .. controls (-174.55,-414.05) and (-184.99,-432.42) .. (-187.87,-437.64)
 .. controls (-190.74,-442.86) and (-205.32,-462.46) .. (-206.94,-465.34)
 .. controls (-208.56,-468.21) and (-221.34,-487.65) .. (-230.16,-495.58)
 .. controls (-238.98,-503.50) and (-250.50,-509.99) .. (-256.44,-512.15)
 .. controls (-262.38,-514.31) and (-278.40,-523.12) .. (-281.64,-531.76)
 .. controls (-284.88,-540.41) and (-286.50,-550.13) .. (-285.78,-557.33)
 .. controls (-285.06,-564.53) and (-282.73,-575.52) .. (-283.81,-581.10)
 .. controls (-284.89,-586.68) and (-285.79,-591.72) .. (-289.03,-594.42)
 .. controls (-292.27,-597.12) and (-296.23,-600.00) .. (-296.23,-600.00)
));
ATTR__id := "l2-2921-5866";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-274.63,-633.14)
 .. controls (-273.37,-629.90) and (-275.53,-625.94) .. (-273.37,-624.32)
 .. controls (-271.21,-622.70) and (-268.15,-620.54) .. (-264.19,-616.58)
 .. controls (-260.23,-612.61) and (-258.25,-604.69) .. (-255.01,-602.53)
 .. controls (-251.77,-600.37) and (-230.89,-596.40) .. (-227.65,-596.94)
 .. controls (-224.41,-597.48) and (-214.33,-596.21) .. (-209.29,-597.65)
 .. controls (-204.24,-599.08) and (-185.70,-602.85) .. (-182.82,-600.86)
 .. controls (-179.94,-598.88) and (-179.94,-601.04) .. (-178.14,-589.89)
 .. controls (-176.34,-578.73) and (-174.90,-555.87) .. (-174.36,-551.73)
 .. controls (-173.82,-547.59) and (-172.38,-515.01) .. (-169.68,-504.76)
 .. controls (-166.98,-494.51) and (-155.65,-465.20) .. (-152.95,-459.80)
 .. controls (-150.25,-454.41) and (-136.75,-428.47) .. (-134.77,-423.97)
 .. controls (-132.79,-419.46) and (-116.41,-378.77) .. (-109.57,-369.77)
 .. controls (-102.73,-360.78) and (-102.01,-351.96) .. (-100.39,-347.28)
 .. controls (-98.77,-342.60) and (-95.53,-332.33) .. (-95.53,-328.19)
 .. controls (-95.53,-324.05) and (-95.17,-309.28) .. (-92.65,-305.68)
 .. controls (-90.13,-302.07) and (-85.45,-286.23) .. (-85.63,-279.76)
 .. controls (-85.81,-273.28) and (-81.68,-252.96) .. (-80.78,-245.59)
 .. controls (-79.88,-238.21) and (-78.08,-235.33) .. (-75.57,-230.65)
 .. controls (-73.05,-225.97) and (-62.61,-208.88) .. (-60.09,-202.75)
 .. controls (-57.57,-196.63) and (-41.17,-162.38) .. (-39.37,-155.89)
 .. controls (-37.56,-149.41) and (-28.21,-126.75) .. (-26.23,-122.43)
 .. controls (-24.25,-118.11) and (-19.57,-107.85) .. (-15.60,-101.00)
 .. controls (-11.64,-94.15) and (0.61,-78.10) .. (4.75,-67.29)
 .. controls (8.90,-56.49) and (11.23,-42.46) .. (11.77,-38.69)
 .. controls (12.31,-34.91) and (14.99,-9.24) .. (14.63,-2.95)
 .. controls (14.27,3.35) and (12.29,14.15) .. (16.62,26.60)
 .. controls (20.95,39.05) and (27.98,49.70) .. (29.06,55.28)
 .. controls (30.14,60.86) and (35.54,73.45) .. (36.44,78.13)
 .. controls (37.34,82.80) and (38.96,102.24) .. (44.01,111.62)
 .. controls (49.05,121.00) and (55.18,136.14) .. (58.96,142.25)
 .. controls (62.74,148.36) and (69.03,159.31) .. (74.07,162.37)
 .. controls (79.11,165.44) and (87.76,167.63) .. (90.64,176.08)
 .. controls (93.52,184.55) and (95.15,192.67) .. (97.67,197.19)
 .. controls (100.20,201.71) and (106.15,218.51) .. (111.74,229.52)
 .. controls (117.32,240.51) and (125.59,255.77) .. (128.64,260.43)
 .. controls (131.69,265.09) and (137.25,278.68) .. (139.94,282.08)
 .. controls (142.64,285.47) and (149.46,295.86) .. (150.90,300.72)
 .. controls (152.34,305.58) and (152.35,314.25) .. (156.50,319.70)
 .. controls (160.66,325.14) and (178.33,343.24) .. (181.03,345.40)
 .. controls (183.73,347.56) and (189.85,354.95) .. (195.24,352.76)
 .. controls (200.64,350.57) and (211.05,343.99) .. (213.02,342.53)
 .. controls (215.00,341.07) and (222.91,335.39) .. (222.91,335.39)
 .. controls (222.91,335.39) and (214.63,333.86) .. (214.46,325.79)
 .. controls (214.30,317.74) and (216.83,310.22) .. (219.36,304.13)
 .. controls (221.89,298.05) and (233.78,276.33) .. (235.94,274.17)
 .. controls (238.10,272.01) and (247.10,260.12) .. (253.75,256.14)
 .. controls (260.40,252.16) and (275.50,245.98) .. (279.82,245.24)
 .. controls (284.13,244.50) and (289.35,246.82) .. (292.04,245.18)
 .. controls (294.74,243.55) and (299.77,240.47) .. (301.93,238.84)
 .. controls (304.09,237.21) and (304.99,237.03) .. (304.09,232.18)
 .. controls (303.20,227.34) and (302.12,227.34) .. (304.82,223.56)
 .. controls (307.52,219.79) and (319.41,212.78) .. (326.42,220.13)
 .. controls (333.44,227.49) and (334.87,238.81) .. (336.13,244.03)
 .. controls (337.39,249.25) and (339.02,255.92) .. (342.08,258.45)
 .. controls (345.14,260.98) and (353.26,269.67) .. (354.70,272.93)
 .. controls (356.14,276.18) and (360.12,282.53) .. (357.24,288.48)
 .. controls (354.36,294.44) and (354.36,294.26) .. (345.35,297.83)
 .. controls (336.35,301.41) and (326.62,304.61) .. (323.73,307.47)
 .. controls (320.84,310.33) and (306.07,315.66) .. (309.14,325.07)
 .. controls (312.22,334.52) and (320.37,348.19) .. (323.26,352.93)
 .. controls (326.15,357.66) and (333.38,380.08) .. (335.36,383.69)
 .. controls (337.35,387.30) and (341.67,399.38) .. (343.12,401.74)
 .. controls (344.56,404.10) and (356.34,437.36) .. (359.40,445.43)
 .. controls (362.41,453.39) and (374.35,467.45) .. (375.93,471.66)
 .. controls (377.54,475.92) and (380.48,483.51) .. (386.30,489.88)
 .. controls (392.25,496.41) and (412.66,511.01) .. (404.82,528.57)
 .. controls (396.96,546.16) and (394.84,547.61) .. (394.36,552.37)
 .. controls (393.88,557.08) and (393.96,566.76) .. (394.34,571.36)
 .. controls (394.72,575.92) and (402.60,588.51) .. (402.80,591.14)
 .. controls (403.00,593.78) and (400.78,593.88) .. (400.71,600.13)
 .. controls (400.63,606.45) and (396.16,606.91) .. (401.08,612.71)
 .. controls (405.33,617.73) and (410.03,618.64) .. (414.01,621.43)
 .. controls (419.86,625.53) and (424.86,637.72) .. (428.52,644.21)
));
ATTR__id := "";
drawoptions();
p_curtain((212.76,386.81),0.0,1.41,(0,0));
drawoptions();
p_stalactite((224.45,380.30),0.0,1.00,(0,0));
drawoptions();
p_stalactite((236.50,370.69),0.0,1.00,(0,0));
drawoptions();
p_stalactite((110.84,350.69),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-14.69,-19.44),0.0,2.00,(0,0));
drawoptions();
p_stalactite((-81.68,-175.36),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-112.46,-223.08),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-107.24,-203.45),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-96.62,-189.77),0.0,1.00,(0,0));
ATTR__id := "l34-588-704";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-289.30,-648.60)
 .. controls (-289.30,-648.60) and (-286.50,-645.48) .. (-283.99,-643.93)
 .. controls (-280.21,-641.59) and (-279.31,-642.31) .. (-277.33,-640.69)
 .. controls (-275.65,-639.32) and (-274.63,-633.14) .. (-274.63,-633.14)
));
ATTR__id := "l35-440-915";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-296.23,-600.00)
 .. controls (-296.23,-600.00) and (-296.95,-600.72) .. (-299.11,-601.98)
 .. controls (-301.27,-603.24) and (-300.19,-605.94) .. (-305.23,-605.04)
 .. controls (-310.27,-604.13) and (-314.22,-604.13) .. (-314.22,-604.13)
));
endfig;
beginfig(35);
ATTR__id := "";
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char49 \char48 \mainfont{} etex,(195.06,301.82),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char51 \mainfont{} etex,(352.71,236.17),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char55 \mainfont{} etex,(441.11,626.83),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char50 \mainfont{} etex,(-253.93,-632.23),0.0,0);
drawoptions();
p_label(btex \thlabel\thhugesize \thfb\char76 \char117 \char109 \char101 \char111 \ \char67 \char97 \char118 \char101 \mainfont{} etex,(-440.89,-669.46),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char112 \char53 \mainfont{} etex,(363.18,397.01),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char51 \mainfont{} etex,(-65.30,-243.24),0.0,0);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char99 \char51 \mainfont{} etex,(-49.11,-211.38),0.0,0);
endfig;
beginfig(36);
s_northarrow(0);
endfig;
beginfig(37);
s_scalebar(10, 1, "\thfb\char109 \mainfont{}");
endfig;
background:=(1.00000,1.00000,1.00000);
transparency:=false;
beginfig(38);
clean_legend_box;
drawoptions();
p_entrance((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(39);
clean_legend_box;
drawoptions();
l_wall_bedrock(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(40);
clean_legend_box;
drawoptions();
l_wall_unsurveyed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(41);
clean_legend_box;
drawoptions();
l_wall_flowstone(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(42);
clean_legend_box;
drawoptions();
p_airdraught((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(43);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions();
p_claychoke((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(44);
clean_legend_box;
drawoptions();
l_floorstep((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(45);
clean_legend_box;
drawoptions();
l_pit((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
drawoptions();
beginfig(46);
clean_legend_box;
drawoptions();
p_gradient((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(47);
clean_legend_box;
drawoptions();
l_rockborder(((.16,.36) -- (.61,.21) -- (.91,.46) -- (.84,.78) -- (.38,.86) -- (.20,.55) -- cycle) inscale)draw_legend_box;
endfig;
beginfig(48);
clean_legend_box;
drawoptions();
p_guano((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(49);
clean_legend_box;
drawoptions();
l_border_visible((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(50);
clean_legend_box;
drawoptions();
a_water(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(51);
clean_legend_box;
drawoptions();
a_sump(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(52);
clean_legend_box;
drawoptions();
a_sand(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(53);
clean_legend_box;
drawoptions();
a_clay(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(54);
clean_legend_box;
drawoptions();
a_pebbles(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(55);
clean_legend_box;
drawoptions();
a_debris(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(56);
clean_legend_box;
drawoptions();
a_flowstone(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(57);
clean_legend_box;
drawoptions();
a_blocks(buildcycle((((-4,-4) -- (4,-4) -- (4,4) -- (-4,4) -- (-4,-4))  inscale)));
draw_legend_box;
endfig;
beginfig(58);
clean_legend_box;
drawoptions();
p_waterflow_permanent((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(59);
clean_legend_box;
drawoptions();
l_flowstone((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(60);
clean_legend_box;
drawoptions();
p_stalactite((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(61);
clean_legend_box;
drawoptions();
p_stalactites((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(62);
clean_legend_box;
drawoptions();
p_stalagmite((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(63);
clean_legend_box;
drawoptions();
p_stalagmites((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(64);
clean_legend_box;
drawoptions();
p_pillar((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(65);
clean_legend_box;
drawoptions();
p_curtain((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(66);
clean_legend_box;
drawoptions();
p_sodastraw((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(67);
clean_legend_box;
drawoptions();
p_crystal((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(68);
clean_legend_box;
drawoptions();
p_rimstonepool((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(69);
s_hgrid(-1, -1, 141.73228, 141.73228);
endfig;
beginfig(70);
s_hgrid(0, -1, 141.73228, 141.73228);
endfig;
beginfig(71);
s_hgrid(1, -1, 141.73228, 141.73228);
endfig;
beginfig(72);
s_hgrid(-1, 0, 141.73228, 141.73228);
endfig;
beginfig(73);
s_hgrid(0, 0, 141.73228, 141.73228);
endfig;
beginfig(74);
s_hgrid(1, 0, 141.73228, 141.73228);
endfig;
beginfig(75);
s_hgrid(-1, 1, 141.73228, 141.73228);
endfig;
beginfig(76);
s_hgrid(0, 1, 141.73228, 141.73228);
endfig;
beginfig(77);
s_hgrid(1, 1, 141.73228, 141.73228);
endfig;
end;
