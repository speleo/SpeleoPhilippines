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
background:=(0.25000,0.25750,1.00000);
def_transparent_rgb(tr_bg, 0.25000, 0.25750, 1.00000);
current_scrap := "romeoSP3@romeo_entrance.romeo";
ATTR__scrap := "romeoSP3";
beginfig(5);
ATTR__survey := "romeo_entrance.romeo";
current_src := "Romeo_entrance.th2 [3157]";
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
current_src := "Romeo_entrance.th2 [2964]";
string area_border[];
area_border[1] := "l318-6244-40656";
drawoptions();
a_blocks(buildcycle(((263.71,217.56)
 -- (277.03,195.24)
 .. controls (277.03,195.24) and (353.36,222.58) .. (352.27,223.66)
 .. controls (351.19,224.74) and (339.67,254.27) .. (339.67,254.27)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2960]";
string area_border[];
area_border[1] := "l319-5706-40728";
drawoptions();
a_blocks(buildcycle(((159.29,248.90)
 -- (194.96,186.59)
 -- (220.14,228.00)
 -- (194.57,248.53)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2940]";
string area_border[];
area_border[1] := "l320-5656-40364";
drawoptions();
a_blocks(buildcycle(((136.25,149.54)
 -- (183.76,129.03)
 -- (220.13,144.86)
 -- (189.91,180.83)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [2936]";
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
current_src := "Romeo_entrance.th2 [2869]";
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
current_src := "Romeo_entrance.th2 [2751]";
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
current_src := "Romeo_entrance.th2 [2738]";
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
current_src := "Romeo_entrance.th2 [2717]";
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
beginfig(6);
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
beginfig(7);
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
beginfig(8);
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
beginfig(9);
current_src := "Romeo_entrance.th2 [2408]";
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
current_src := "Romeo_entrance.th2 [2392]";
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
current_src := "Romeo_entrance.th2 [2377]";
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
current_src := "Romeo_entrance.th2 [2143]";
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
current_src := "Romeo_entrance.th2 [2117]";
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
current_src := "Romeo_entrance.th2 [2024]";
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
current_src := "Romeo_entrance.th2 [1981]";
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
current_src := "Romeo_entrance.th2 [1955]";
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
current_src := "Romeo_entrance.th2 [1935]";
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
current_src := "Romeo_entrance.th2 [1888]";
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
current_src := "Romeo_entrance.th2 [1876]";
string area_border[];
area_border[1] := "l332-6706-40886";
drawoptions();
a_blocks(buildcycle(((-852.77,749.34)
 -- (-835.49,705.42)
 -- (-822.89,705.78)
 -- (-808.49,752.22)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1860]";
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
beginfig(10);
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
beginfig(11);
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
beginfig(12);
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
beginfig(13);
current_src := "Romeo_entrance.th2 [1533]";
string area_border[];
area_border[1] := "l173-10224-23120";
area_border[2] := "l177-10200-24128";
area_border[3] := "l588-10096-23664";
drawoptions();
a_clay(buildcycle(((519.54,864.09)
 .. controls (521.88,864.82) and (527.64,868.62) .. (531.61,870.43)
 .. controls (535.57,872.25) and (548.00,882.00) .. (550.34,884.34)
 .. controls (552.68,886.69) and (562.23,897.71) .. (566.38,903.14)
 .. controls (570.52,908.56) and (577.01,920.29) .. (579.53,924.97)
 .. controls (582.05,929.65) and (589.94,945.40) .. (591.74,948.25)
 .. controls (593.53,951.10) and (596.01,972.56) .. (596.54,977.57)
 .. controls (597.08,982.59) and (596.17,997.14) .. (596.17,1005.43)
 .. controls (596.18,1013.73) and (593.65,1015.34) .. (592.75,1017.86)
 .. controls (591.85,1020.38) and (596.73,1022.22) .. (597.63,1023.14)
 .. controls (598.53,1024.05) and (612.62,1029.26) .. (613.88,1029.63)
 .. controls (615.15,1030.00) and (619.48,1030.58) .. (621.64,1032.05)
 .. controls (623.81,1033.51) and (625.62,1036.42) .. (626.16,1037.32)
 .. controls (626.70,1038.23) and (624.54,1042.19) .. (624.00,1043.99)
 .. controls (623.46,1045.79) and (620.39,1055.09) .. (620.38,1058.30)
 .. controls (620.37,1061.51) and (617.08,1072.65) .. (613.99,1077.23)
 .. controls (610.90,1081.80) and (605.43,1083.65) .. (593.72,1094.12)
 .. controls (581.96,1104.63) and (564.61,1115.33) .. (558.34,1117.79)
 .. controls (552.07,1120.25) and (542.94,1123.83) .. (538.81,1126.41)
 .. controls (534.69,1128.99) and (532.89,1129.53) .. (530.37,1130.25)
 .. controls (527.85,1130.96) and (528.37,1126.94) .. (526.92,1124.91)
 .. controls (525.47,1122.89) and (518.21,1112.58) .. (512.03,1100.34)
 .. controls (505.90,1088.19) and (495.08,1087.26) .. (491.12,1085.82)
 .. controls (487.16,1084.38) and (471.16,1080.30) .. (464.51,1078.03)
 .. controls (457.88,1075.75) and (444.07,1070.91) .. (439.22,1070.60)
 .. controls (434.38,1070.30) and (418.05,1066.52) .. (415.89,1065.82)
 .. controls (413.74,1065.11) and (402.76,1063.69) .. (400.06,1063.32)
 .. controls (397.35,1062.95) and (373.00,1060.59) .. (370.83,1060.21)
 .. controls (368.67,1059.83) and (362.88,1066.39) .. (362.88,1066.39)
),
((555.45,1011.03)
 .. controls (555.45,1011.03) and (554.69,1046.16) .. (551.80,1061.94)
 .. controls (548.91,1077.76) and (561.15,1079.93) .. (563.31,1092.18)
 .. controls (565.48,1104.45) and (576.26,1110.85) .. (576.26,1110.85)
),
((555.45,1011.03)
 -- (486.36,944.87)
 -- (362.88,1066.39)
)));
current_src := "Romeo_entrance.th2 [1460]";
string area_border[];
area_border[1] := "l163-9132-20000";
area_border[2] := "l606-8760-19828";
area_border[3] := "l181-8986-19593";
area_border[4] := "l607-9326-19350";
area_border[5] := "l183-9896-18512";
area_border[6] := "l608-9224-17162";
area_border[7] := "l187-8364-15472";
area_border[8] := "l609-8620-15342";
area_border[9] := "l184-9852-17572";
area_border[10] := "l610-10188-18254";
drawoptions();
a_water(buildcycle(((274.08,341.88)
 -- (447.61,329.72)
),
((274.08,341.88)
 -- (307.57,285.25)
),
((396.50,244.80)
 .. controls (396.50,244.80) and (390.92,245.70) .. (388.40,245.70)
 .. controls (385.88,245.69) and (382.64,244.61) .. (377.78,245.87)
 .. controls (372.92,247.13) and (372.02,249.47) .. (369.86,252.71)
 .. controls (367.70,255.95) and (366.44,256.85) .. (363.74,261.89)
 .. controls (361.04,266.94) and (354.38,266.57) .. (348.62,264.59)
 .. controls (342.86,262.60) and (337.64,260.79) .. (331.88,261.69)
 .. controls (326.12,262.58) and (326.48,264.02) .. (322.16,266.36)
 .. controls (317.84,268.70) and (318.02,272.12) .. (316.58,275.90)
 .. controls (315.13,279.67) and (309.37,284.71) .. (307.57,285.25)
),
((396.50,244.80)
 -- (413.60,92.15)
),
((391.46,-161.81)
 .. controls (394.52,-159.29) and (405.50,-152.45) .. (409.64,-145.43)
 .. controls (413.78,-138.41) and (415.94,-124.73) .. (418.82,-116.26)
 .. controls (421.70,-107.80) and (425.12,-107.27) .. (431.78,-103.85)
 .. controls (438.44,-100.43) and (454.64,-86.40) .. (458.96,-82.80)
 .. controls (463.28,-79.21) and (482.00,-56.35) .. (485.96,-50.23)
 .. controls (489.92,-44.11) and (503.24,-20.17) .. (505.58,-8.47)
 .. controls (507.92,3.23) and (506.30,49.13) .. (505.22,53.45)
 .. controls (504.14,57.77) and (500.90,71.63) .. (499.28,83.87)
 .. controls (497.66,96.12) and (490.28,121.51) .. (487.22,127.45)
 .. controls (484.16,133.40) and (474.80,141.32) .. (467.24,143.66)
 .. controls (459.68,146.00) and (446.90,131.77) .. (443.84,128.53)
 .. controls (440.78,125.28) and (431.60,111.60) .. (429.62,106.92)
 .. controls (427.64,102.24) and (415.04,93.41) .. (413.60,92.15)
),
((391.46,-161.81)
 .. controls (391.46,-161.81) and (195.27,-399.24) .. (221.55,-435.95)
),
((221.55,-435.95)
 .. controls (222.63,-439.91) and (226.59,-451.07) .. (226.59,-462.23)
 .. controls (226.59,-473.39) and (222.63,-484.19) .. (224.79,-492.47)
 .. controls (226.95,-500.75) and (224.43,-510.11) .. (226.95,-518.75)
 .. controls (229.47,-527.39) and (227.67,-536.03) .. (231.63,-539.99)
 .. controls (235.59,-543.95) and (244.95,-547.91) .. (248.19,-551.15)
),
((248.19,-551.15)
 -- (306.14,-433.25)
),
((543.37,-63.40)
 .. controls (541.21,-65.73) and (521.05,-81.21) .. (514.75,-86.60)
 .. controls (508.45,-92.00) and (488.84,-101.53) .. (485.24,-108.37)
 .. controls (481.64,-115.21) and (475.34,-123.85) .. (473.00,-130.32)
 .. controls (470.66,-136.80) and (472.27,-147.78) .. (471.19,-153.00)
 .. controls (470.11,-158.22) and (470.29,-165.60) .. (466.51,-176.39)
 .. controls (462.73,-187.19) and (454.81,-200.33) .. (453.01,-207.70)
 .. controls (451.21,-215.08) and (442.93,-222.64) .. (440.05,-229.84)
 .. controls (437.17,-237.04) and (427.81,-250.00) .. (424.75,-253.61)
 .. controls (421.69,-257.21) and (395.96,-283.50) .. (392.36,-290.34)
 .. controls (388.76,-297.18) and (367.88,-324.90) .. (363.74,-330.12)
 .. controls (359.60,-335.34) and (351.50,-351.17) .. (348.62,-358.01)
 .. controls (345.74,-364.85) and (344.48,-367.37) .. (338.90,-372.23)
 .. controls (333.32,-377.09) and (327.38,-383.93) .. (322.52,-390.05)
 .. controls (317.66,-396.17) and (310.28,-407.87) .. (309.38,-412.73)
 .. controls (308.48,-417.59) and (306.68,-428.57) .. (306.14,-433.25)
),
((543.37,-63.40)
 -- (562.82,77.72)
 -- (614.28,240.39)
 -- (447.61,329.72)
)));
current_src := "Romeo_entrance.th2 [1441]";
string area_border[];
area_border[1] := "l29-9392-18376";
area_border[2] := "l187-8364-15472";
area_border[3] := "l30-9984-17468";
area_border[4] := "l189-8350-14756";
area_border[5] := "l189-8350-14756";
drawoptions();
a_blocks(buildcycle(((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
),
((221.55,-435.95)
 .. controls (222.63,-439.91) and (226.59,-451.07) .. (226.59,-462.23)
 .. controls (226.59,-473.39) and (222.63,-484.19) .. (224.79,-492.47)
 .. controls (226.95,-500.75) and (224.43,-510.11) .. (226.95,-518.75)
 .. controls (229.47,-527.39) and (227.67,-536.03) .. (231.63,-539.99)
 .. controls (235.59,-543.95) and (244.95,-547.91) .. (248.19,-551.15)
),
((-77.80,-1335.57)
 .. controls (-73.66,-1326.93) and (-80.85,-1310.36) .. (-72.93,-1290.19)
 .. controls (-65.01,-1270.03) and (-54.93,-1252.02) .. (-58.53,-1230.43)
 .. controls (-62.13,-1208.83) and (-65.02,-1182.20) .. (-68.62,-1171.41)
 .. controls (-72.23,-1160.62) and (-71.50,-1138.29) .. (-70.78,-1125.33)
 .. controls (-70.05,-1112.36) and (-71.48,-1088.60) .. (-59.96,-1071.32)
 .. controls (-48.44,-1054.04) and (-34.76,-1019.48) .. (-14.60,-1003.64)
 .. controls (5.56,-987.79) and (46.59,-945.33) .. (53.79,-932.37)
 .. controls (60.99,-919.40) and (97.72,-886.27) .. (103.48,-873.31)
 .. controls (109.24,-860.36) and (132.28,-816.44) .. (135.88,-804.93)
 .. controls (139.47,-793.41) and (145.94,-724.30) .. (187.71,-693.33)
 .. controls (229.47,-662.38) and (229.47,-624.94) .. (235.23,-614.86)
 .. controls (240.99,-604.78) and (243.87,-552.23) .. (243.87,-547.91)
 .. controls (243.87,-543.59) and (246.03,-519.83) .. (254.67,-504.71)
 .. controls (263.31,-489.59) and (278.42,-468.71) .. (285.62,-457.91)
 .. controls (292.82,-447.11) and (309.38,-415.43) .. (315.14,-408.95)
 .. controls (320.90,-402.47) and (347.54,-384.47) .. (356.18,-374.39)
 .. controls (364.82,-364.31) and (438.26,-284.39) .. (444.74,-272.15)
 .. controls (451.21,-259.90) and (456.97,-236.86) .. (461.29,-225.34)
 .. controls (465.61,-213.82) and (477.13,-203.75) .. (483.61,-194.39)
 .. controls (490.09,-185.04) and (510.97,-159.13) .. (510.97,-148.33)
 .. controls (510.97,-137.53) and (519.61,-108.02) .. (529.69,-91.47)
 .. controls (539.77,-74.91) and (544.10,-36.03) .. (544.10,-30.27)
 .. controls (544.10,-24.51) and (549.86,23.73) .. (547.70,35.97)
 .. controls (545.54,48.21) and (537.62,71.26) .. (546.26,90.69)
 .. controls (554.90,110.13) and (570.02,138.93) .. (576.50,150.45)
 .. controls (582.98,161.96) and (598.81,189.31) .. (597.37,201.55)
 .. controls (595.93,213.79) and (593.95,235.92) .. (568.03,243.14)
 .. controls (542.12,250.36) and (505.94,254.15) .. (493.70,253.43)
 .. controls (481.46,252.71) and (452.67,247.68) .. (437.55,266.41)
 .. controls (422.43,285.13) and (419.54,281.53) .. (417.38,287.29)
),
((183.03,-552.22)
 .. controls (183.03,-552.22) and (190.23,-585.70) .. (189.14,-595.78)
 .. controls (188.06,-605.86) and (184.10,-627.82) .. (184.46,-634.30)
 .. controls (184.82,-640.78) and (179.42,-647.62) .. (189.86,-644.02)
 .. controls (200.30,-640.42) and (211.82,-626.38) .. (214.71,-621.34)
 .. controls (217.59,-616.30) and (225.51,-605.86) .. (230.19,-598.66)
 .. controls (234.87,-591.46) and (245.67,-584.26) .. (245.67,-584.26)
),
((183.03,-552.22)
 .. controls (183.03,-552.22) and (190.23,-585.70) .. (189.14,-595.78)
 .. controls (188.06,-605.86) and (184.10,-627.82) .. (184.46,-634.30)
 .. controls (184.82,-640.78) and (179.42,-647.62) .. (189.86,-644.02)
 .. controls (200.30,-640.42) and (211.82,-626.38) .. (214.71,-621.34)
 .. controls (217.59,-616.30) and (225.51,-605.86) .. (230.19,-598.66)
 .. controls (234.87,-591.46) and (245.67,-584.26) .. (245.67,-584.26)
)));
current_src := "Romeo_entrance.th2 [1375]";
string area_border[];
area_border[1] := "l30-9984-17468";
area_border[2] := "l54-5320-8936";
area_border[3] := "l200-6296-10916";
area_border[4] := "l196-6316-11828";
area_border[5] := "l197-6472-11896";
drawoptions();
a_water(buildcycle(((-77.80,-1335.57)
 .. controls (-73.66,-1326.93) and (-80.85,-1310.36) .. (-72.93,-1290.19)
 .. controls (-65.01,-1270.03) and (-54.93,-1252.02) .. (-58.53,-1230.43)
 .. controls (-62.13,-1208.83) and (-65.02,-1182.20) .. (-68.62,-1171.41)
 .. controls (-72.23,-1160.62) and (-71.50,-1138.29) .. (-70.78,-1125.33)
 .. controls (-70.05,-1112.36) and (-71.48,-1088.60) .. (-59.96,-1071.32)
 .. controls (-48.44,-1054.04) and (-34.76,-1019.48) .. (-14.60,-1003.64)
 .. controls (5.56,-987.79) and (46.59,-945.33) .. (53.79,-932.37)
 .. controls (60.99,-919.40) and (97.72,-886.27) .. (103.48,-873.31)
 .. controls (109.24,-860.36) and (132.28,-816.44) .. (135.88,-804.93)
 .. controls (139.47,-793.41) and (145.94,-724.30) .. (187.71,-693.33)
 .. controls (229.47,-662.38) and (229.47,-624.94) .. (235.23,-614.86)
 .. controls (240.99,-604.78) and (243.87,-552.23) .. (243.87,-547.91)
 .. controls (243.87,-543.59) and (246.03,-519.83) .. (254.67,-504.71)
 .. controls (263.31,-489.59) and (278.42,-468.71) .. (285.62,-457.91)
 .. controls (292.82,-447.11) and (309.38,-415.43) .. (315.14,-408.95)
 .. controls (320.90,-402.47) and (347.54,-384.47) .. (356.18,-374.39)
 .. controls (364.82,-364.31) and (438.26,-284.39) .. (444.74,-272.15)
 .. controls (451.21,-259.90) and (456.97,-236.86) .. (461.29,-225.34)
 .. controls (465.61,-213.82) and (477.13,-203.75) .. (483.61,-194.39)
 .. controls (490.09,-185.04) and (510.97,-159.13) .. (510.97,-148.33)
 .. controls (510.97,-137.53) and (519.61,-108.02) .. (529.69,-91.47)
 .. controls (539.77,-74.91) and (544.10,-36.03) .. (544.10,-30.27)
 .. controls (544.10,-24.51) and (549.86,23.73) .. (547.70,35.97)
 .. controls (545.54,48.21) and (537.62,71.26) .. (546.26,90.69)
 .. controls (554.90,110.13) and (570.02,138.93) .. (576.50,150.45)
 .. controls (582.98,161.96) and (598.81,189.31) .. (597.37,201.55)
 .. controls (595.93,213.79) and (593.95,235.92) .. (568.03,243.14)
 .. controls (542.12,250.36) and (505.94,254.15) .. (493.70,253.43)
 .. controls (481.46,252.71) and (452.67,247.68) .. (437.55,266.41)
 .. controls (422.43,285.13) and (419.54,281.53) .. (417.38,287.29)
),
((-597.00,-1944.58)
 .. controls (-594.89,-1941.95) and (-590.31,-1936.00) .. (-585.51,-1932.67)
 .. controls (-580.69,-1929.33) and (-572.62,-1926.66) .. (-567.93,-1925.92)
 .. controls (-563.23,-1925.18) and (-543.52,-1917.47) .. (-540.28,-1915.67)
 .. controls (-537.04,-1913.87) and (-519.29,-1903.54) .. (-514.81,-1899.25)
 .. controls (-510.32,-1894.95) and (-502.22,-1875.86) .. (-499.68,-1868.81)
 .. controls (-497.14,-1861.77) and (-491.75,-1846.48) .. (-490.68,-1841.10)
 .. controls (-489.62,-1835.73) and (-488.39,-1822.28) .. (-487.49,-1817.42)
 .. controls (-486.59,-1812.56) and (-482.98,-1803.54) .. (-480.27,-1798.31)
 .. controls (-477.57,-1793.08) and (-469.08,-1783.13) .. (-462.40,-1777.70)
 .. controls (-455.72,-1772.27) and (-441.83,-1763.22) .. (-438.04,-1761.06)
 .. controls (-434.26,-1758.89) and (-425.43,-1750.59) .. (-422.72,-1746.81)
 .. controls (-420.02,-1743.03) and (-410.12,-1730.42) .. (-406.51,-1727.72)
 .. controls (-402.91,-1725.01) and (-390.48,-1710.23) .. (-386.69,-1707.53)
 .. controls (-382.91,-1704.82) and (-367.60,-1691.31) .. (-359.68,-1682.67)
 .. controls (-351.77,-1674.04) and (-341.34,-1665.06) .. (-335.04,-1662.37)
 .. controls (-328.75,-1659.68) and (-308.09,-1646.05) .. (-304.13,-1642.46)
 .. controls (-300.18,-1638.88) and (-272.67,-1617.86) .. (-266.37,-1612.64)
 .. controls (-260.07,-1607.42) and (-240.99,-1592.66) .. (-234.69,-1587.81)
 .. controls (-228.40,-1582.95) and (-191.93,-1545.98) .. (-187.61,-1542.02)
 .. controls (-183.29,-1538.07) and (-177.53,-1520.25) .. (-174.65,-1512.14)
 .. controls (-171.76,-1504.03) and (-157.69,-1480.59) .. (-155.71,-1476.45)
 .. controls (-153.73,-1472.30) and (-131.95,-1430.55) .. (-128.71,-1425.51)
 .. controls (-125.47,-1420.47) and (-116.29,-1409.14) .. (-113.77,-1405.18)
 .. controls (-111.25,-1401.22) and (-90.93,-1371.01) .. (-89.49,-1364.36)
 .. controls (-88.06,-1357.71) and (-79.42,-1340.62) .. (-77.80,-1335.57)
),
((-147.81,-1246.99)
 .. controls (-147.81,-1246.99) and (-144.93,-1261.75) .. (-145.64,-1275.42)
 .. controls (-146.36,-1289.09) and (-148.15,-1313.56) .. (-145.27,-1321.12)
 .. controls (-142.39,-1328.69) and (-137.72,-1326.89) .. (-141.67,-1335.17)
 .. controls (-145.63,-1343.44) and (-166.16,-1364.69) .. (-172.66,-1378.39)
 .. controls (-179.15,-1392.08) and (-182.76,-1408.65) .. (-182.75,-1417.64)
 .. controls (-182.74,-1426.63) and (-198.55,-1469.79) .. (-204.32,-1477.35)
 .. controls (-210.08,-1484.91) and (-213.69,-1500.77) .. (-216.57,-1512.66)
 .. controls (-219.45,-1524.54) and (-219.81,-1542.16) .. (-225.56,-1545.39)
 .. controls (-231.31,-1548.62) and (-235.26,-1549.69) .. (-244.26,-1549.32)
 .. controls (-253.25,-1548.96) and (-261.18,-1551.48) .. (-272.35,-1557.26)
 .. controls (-283.53,-1563.04) and (-298.66,-1564.52) .. (-305.15,-1568.49)
 .. controls (-311.64,-1572.45) and (-313.08,-1572.09) .. (-315.60,-1582.53)
 .. controls (-318.11,-1592.95) and (-320.62,-1597.98) .. (-320.24,-1607.31)
 .. controls (-319.86,-1616.64) and (-328.48,-1618.78) .. (-319.12,-1624.17)
 .. controls (-309.75,-1629.55) and (-305.06,-1632.78) .. (-298.94,-1630.98)
 .. controls (-292.82,-1629.19) and (-278.77,-1632.76) .. (-278.77,-1632.76)
),
((-205.37,-1267.09)
 .. controls (-205.37,-1267.09) and (-196.38,-1267.10) .. (-189.90,-1266.39)
 .. controls (-183.43,-1265.67) and (-171.55,-1264.24) .. (-167.60,-1263.17)
 .. controls (-163.64,-1262.09) and (-146.01,-1252.75) .. (-139.18,-1248.08)
 .. controls (-132.34,-1243.41) and (-124.07,-1232.25) .. (-123.35,-1223.97)
 .. controls (-122.62,-1215.68) and (-121.90,-1207.76) .. (-120.46,-1196.95)
 .. controls (-119.01,-1186.15) and (-119.37,-1170.67) .. (-121.17,-1161.67)
 .. controls (-122.97,-1152.67) and (-130.17,-1143.67) .. (-134.85,-1141.15)
 .. controls (-139.53,-1138.63) and (-154.64,-1127.47) .. (-154.64,-1127.47)
),
((-134.13,-1147.99)
 .. controls (-128.73,-1143.67) and (-128.73,-1136.11) .. (-125.49,-1132.52)
 .. controls (-122.25,-1128.92) and (-109.65,-1122.44) .. (-105.33,-1119.20)
 .. controls (-101.01,-1115.96) and (-101.73,-1112.72) .. (-94.89,-1112.00)
 .. controls (-88.05,-1111.28) and (-68.61,-1115.96) .. (-66.09,-1118.48)
)));
current_src := "Romeo_entrance.th2 [1355]";
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
a_water(buildcycle(((-77.80,-1335.57)
 .. controls (-73.66,-1326.93) and (-80.85,-1310.36) .. (-72.93,-1290.19)
 .. controls (-65.01,-1270.03) and (-54.93,-1252.02) .. (-58.53,-1230.43)
 .. controls (-62.13,-1208.83) and (-65.02,-1182.20) .. (-68.62,-1171.41)
 .. controls (-72.23,-1160.62) and (-71.50,-1138.29) .. (-70.78,-1125.33)
 .. controls (-70.05,-1112.36) and (-71.48,-1088.60) .. (-59.96,-1071.32)
 .. controls (-48.44,-1054.04) and (-34.76,-1019.48) .. (-14.60,-1003.64)
 .. controls (5.56,-987.79) and (46.59,-945.33) .. (53.79,-932.37)
 .. controls (60.99,-919.40) and (97.72,-886.27) .. (103.48,-873.31)
 .. controls (109.24,-860.36) and (132.28,-816.44) .. (135.88,-804.93)
 .. controls (139.47,-793.41) and (145.94,-724.30) .. (187.71,-693.33)
 .. controls (229.47,-662.38) and (229.47,-624.94) .. (235.23,-614.86)
 .. controls (240.99,-604.78) and (243.87,-552.23) .. (243.87,-547.91)
 .. controls (243.87,-543.59) and (246.03,-519.83) .. (254.67,-504.71)
 .. controls (263.31,-489.59) and (278.42,-468.71) .. (285.62,-457.91)
 .. controls (292.82,-447.11) and (309.38,-415.43) .. (315.14,-408.95)
 .. controls (320.90,-402.47) and (347.54,-384.47) .. (356.18,-374.39)
 .. controls (364.82,-364.31) and (438.26,-284.39) .. (444.74,-272.15)
 .. controls (451.21,-259.90) and (456.97,-236.86) .. (461.29,-225.34)
 .. controls (465.61,-213.82) and (477.13,-203.75) .. (483.61,-194.39)
 .. controls (490.09,-185.04) and (510.97,-159.13) .. (510.97,-148.33)
 .. controls (510.97,-137.53) and (519.61,-108.02) .. (529.69,-91.47)
 .. controls (539.77,-74.91) and (544.10,-36.03) .. (544.10,-30.27)
 .. controls (544.10,-24.51) and (549.86,23.73) .. (547.70,35.97)
 .. controls (545.54,48.21) and (537.62,71.26) .. (546.26,90.69)
 .. controls (554.90,110.13) and (570.02,138.93) .. (576.50,150.45)
 .. controls (582.98,161.96) and (598.81,189.31) .. (597.37,201.55)
 .. controls (595.93,213.79) and (593.95,235.92) .. (568.03,243.14)
 .. controls (542.12,250.36) and (505.94,254.15) .. (493.70,253.43)
 .. controls (481.46,252.71) and (452.67,247.68) .. (437.55,266.41)
 .. controls (422.43,285.13) and (419.54,281.53) .. (417.38,287.29)
),
((-13.52,-1013.00)
 .. controls (-15.32,-1013.72) and (-31.88,-1015.16) .. (-35.48,-1019.84)
 .. controls (-39.09,-1024.52) and (-43.77,-1027.76) .. (-52.41,-1032.80)
 .. controls (-61.05,-1037.84) and (-65.73,-1039.28) .. (-69.69,-1045.76)
 .. controls (-73.65,-1052.24) and (-74.36,-1059.08) .. (-74.00,-1065.56)
 .. controls (-73.64,-1072.04) and (-77.60,-1076.72) .. (-77.60,-1082.12)
 .. controls (-77.61,-1087.52) and (-76.89,-1089.68) .. (-75.45,-1092.20)
 .. controls (-74.01,-1094.72) and (-64.65,-1103.72) .. (-64.65,-1103.72)
),
((-124.05,-1061.24)
 .. controls (-124.05,-1065.20) and (-124.42,-1078.89) .. (-122.98,-1081.41)
 .. controls (-121.54,-1083.93) and (-123.34,-1091.13) .. (-117.22,-1092.93)
 .. controls (-111.10,-1094.73) and (-97.05,-1095.80) .. (-92.37,-1094.36)
 .. controls (-87.69,-1092.92) and (-83.01,-1090.04) .. (-80.85,-1090.04)
 .. controls (-78.69,-1090.04) and (-72.93,-1088.96) .. (-72.93,-1088.96)
),
((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
),
((-94.53,-1004.00)
 .. controls (-92.37,-1004.01) and (-54.93,-989.97) .. (-43.77,-979.53)
 .. controls (-32.61,-969.08) and (-13.16,-954.68) .. (-3.08,-948.20)
 .. controls (6.99,-941.72) and (15.63,-939.92) .. (21.39,-937.41)
 .. controls (27.15,-934.89) and (36.51,-912.92) .. (36.87,-906.08)
 .. controls (37.23,-899.24) and (41.20,-880.52) .. (44.80,-868.28)
 .. controls (48.39,-856.04) and (52.35,-844.53) .. (55.23,-835.89)
 .. controls (58.11,-827.25) and (65.67,-809.25) .. (69.63,-802.05)
 .. controls (73.59,-794.85) and (87.27,-765.33) .. (89.07,-755.25)
 .. controls (90.87,-745.17) and (86.19,-721.05) .. (84.75,-714.93)
 .. controls (83.32,-708.81) and (79.00,-694.05) .. (77.92,-691.89)
),
((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
),
((92.67,-682.17)
 .. controls (98.43,-678.21) and (125.07,-668.14) .. (129.39,-666.70)
 .. controls (133.71,-665.26) and (163.58,-652.30) .. (168.26,-650.14)
 .. controls (172.94,-647.98) and (186.62,-643.30) .. (186.62,-643.30)
),
((183.03,-552.22)
 .. controls (183.03,-552.22) and (190.23,-585.70) .. (189.14,-595.78)
 .. controls (188.06,-605.86) and (184.10,-627.82) .. (184.46,-634.30)
 .. controls (184.82,-640.78) and (179.42,-647.62) .. (189.86,-644.02)
 .. controls (200.30,-640.42) and (211.82,-626.38) .. (214.71,-621.34)
 .. controls (217.59,-616.30) and (225.51,-605.86) .. (230.19,-598.66)
 .. controls (234.87,-591.46) and (245.67,-584.26) .. (245.67,-584.26)
)));
current_src := "Romeo_entrance.th2 [1346]";
string area_border[];
area_border[1] := "l195-6512-12060";
area_border[2] := "l194-6756-12360";
area_border[3] := "l30-9984-17468";
area_border[4] := "l197-6472-11896";
area_border[5] := "l196-6316-11828";
area_border[6] := "l29-9392-18376";
drawoptions();
a_blocks(buildcycle(((-124.05,-1061.24)
 .. controls (-124.05,-1065.20) and (-124.42,-1078.89) .. (-122.98,-1081.41)
 .. controls (-121.54,-1083.93) and (-123.34,-1091.13) .. (-117.22,-1092.93)
 .. controls (-111.10,-1094.73) and (-97.05,-1095.80) .. (-92.37,-1094.36)
 .. controls (-87.69,-1092.92) and (-83.01,-1090.04) .. (-80.85,-1090.04)
 .. controls (-78.69,-1090.04) and (-72.93,-1088.96) .. (-72.93,-1088.96)
),
((-13.52,-1013.00)
 .. controls (-15.32,-1013.72) and (-31.88,-1015.16) .. (-35.48,-1019.84)
 .. controls (-39.09,-1024.52) and (-43.77,-1027.76) .. (-52.41,-1032.80)
 .. controls (-61.05,-1037.84) and (-65.73,-1039.28) .. (-69.69,-1045.76)
 .. controls (-73.65,-1052.24) and (-74.36,-1059.08) .. (-74.00,-1065.56)
 .. controls (-73.64,-1072.04) and (-77.60,-1076.72) .. (-77.60,-1082.12)
 .. controls (-77.61,-1087.52) and (-76.89,-1089.68) .. (-75.45,-1092.20)
 .. controls (-74.01,-1094.72) and (-64.65,-1103.72) .. (-64.65,-1103.72)
),
((-77.80,-1335.57)
 .. controls (-73.66,-1326.93) and (-80.85,-1310.36) .. (-72.93,-1290.19)
 .. controls (-65.01,-1270.03) and (-54.93,-1252.02) .. (-58.53,-1230.43)
 .. controls (-62.13,-1208.83) and (-65.02,-1182.20) .. (-68.62,-1171.41)
 .. controls (-72.23,-1160.62) and (-71.50,-1138.29) .. (-70.78,-1125.33)
 .. controls (-70.05,-1112.36) and (-71.48,-1088.60) .. (-59.96,-1071.32)
 .. controls (-48.44,-1054.04) and (-34.76,-1019.48) .. (-14.60,-1003.64)
 .. controls (5.56,-987.79) and (46.59,-945.33) .. (53.79,-932.37)
 .. controls (60.99,-919.40) and (97.72,-886.27) .. (103.48,-873.31)
 .. controls (109.24,-860.36) and (132.28,-816.44) .. (135.88,-804.93)
 .. controls (139.47,-793.41) and (145.94,-724.30) .. (187.71,-693.33)
 .. controls (229.47,-662.38) and (229.47,-624.94) .. (235.23,-614.86)
 .. controls (240.99,-604.78) and (243.87,-552.23) .. (243.87,-547.91)
 .. controls (243.87,-543.59) and (246.03,-519.83) .. (254.67,-504.71)
 .. controls (263.31,-489.59) and (278.42,-468.71) .. (285.62,-457.91)
 .. controls (292.82,-447.11) and (309.38,-415.43) .. (315.14,-408.95)
 .. controls (320.90,-402.47) and (347.54,-384.47) .. (356.18,-374.39)
 .. controls (364.82,-364.31) and (438.26,-284.39) .. (444.74,-272.15)
 .. controls (451.21,-259.90) and (456.97,-236.86) .. (461.29,-225.34)
 .. controls (465.61,-213.82) and (477.13,-203.75) .. (483.61,-194.39)
 .. controls (490.09,-185.04) and (510.97,-159.13) .. (510.97,-148.33)
 .. controls (510.97,-137.53) and (519.61,-108.02) .. (529.69,-91.47)
 .. controls (539.77,-74.91) and (544.10,-36.03) .. (544.10,-30.27)
 .. controls (544.10,-24.51) and (549.86,23.73) .. (547.70,35.97)
 .. controls (545.54,48.21) and (537.62,71.26) .. (546.26,90.69)
 .. controls (554.90,110.13) and (570.02,138.93) .. (576.50,150.45)
 .. controls (582.98,161.96) and (598.81,189.31) .. (597.37,201.55)
 .. controls (595.93,213.79) and (593.95,235.92) .. (568.03,243.14)
 .. controls (542.12,250.36) and (505.94,254.15) .. (493.70,253.43)
 .. controls (481.46,252.71) and (452.67,247.68) .. (437.55,266.41)
 .. controls (422.43,285.13) and (419.54,281.53) .. (417.38,287.29)
),
((-134.13,-1147.99)
 .. controls (-128.73,-1143.67) and (-128.73,-1136.11) .. (-125.49,-1132.52)
 .. controls (-122.25,-1128.92) and (-109.65,-1122.44) .. (-105.33,-1119.20)
 .. controls (-101.01,-1115.96) and (-101.73,-1112.72) .. (-94.89,-1112.00)
 .. controls (-88.05,-1111.28) and (-68.61,-1115.96) .. (-66.09,-1118.48)
),
((-205.37,-1267.09)
 .. controls (-205.37,-1267.09) and (-196.38,-1267.10) .. (-189.90,-1266.39)
 .. controls (-183.43,-1265.67) and (-171.55,-1264.24) .. (-167.60,-1263.17)
 .. controls (-163.64,-1262.09) and (-146.01,-1252.75) .. (-139.18,-1248.08)
 .. controls (-132.34,-1243.41) and (-124.07,-1232.25) .. (-123.35,-1223.97)
 .. controls (-122.62,-1215.68) and (-121.90,-1207.76) .. (-120.46,-1196.95)
 .. controls (-119.01,-1186.15) and (-119.37,-1170.67) .. (-121.17,-1161.67)
 .. controls (-122.97,-1152.67) and (-130.17,-1143.67) .. (-134.85,-1141.15)
 .. controls (-139.53,-1138.63) and (-154.64,-1127.47) .. (-154.64,-1127.47)
),
((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
)));
current_src := "Romeo_entrance.th2 [1282]";
string area_border[];
area_border[1] := "l624-5116-9242";
drawoptions();
a_blocks(buildcycle(((-499.73,-1638.05)
 -- (-484.32,-1648.59)
 -- (-456.95,-1640.66)
 -- (-450.18,-1664.16)
 -- (-401.48,-1711.52)
 -- (-375.53,-1691.32)
 -- (-327.33,-1649.27)
 -- (-333.52,-1616.61)
 -- (-358.70,-1599.67)
 -- (-377.02,-1598.17)
 -- (-407.94,-1613.22)
 -- (-450.06,-1621.14)
 -- (-480.27,-1614.25)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1256]";
string area_border[];
area_border[1] := "l627-5152-9338";
drawoptions();
a_sand(buildcycle(((-490.39,-1636.28)
 .. controls (-490.39,-1636.28) and (-492.50,-1618.58) .. (-470.21,-1621.49)
 .. controls (-447.91,-1624.41) and (-437.12,-1627.63) .. (-421.26,-1620.42)
 .. controls (-405.42,-1613.22) and (-378.10,-1599.24) .. (-366.97,-1593.53)
 .. controls (-355.84,-1587.81) and (-348.66,-1577.07) .. (-330.70,-1575.67)
 .. controls (-312.72,-1574.27) and (-318.84,-1578.93) .. (-324.57,-1596.53)
 .. controls (-330.29,-1614.11) and (-328.12,-1620.93) .. (-324.14,-1628.47)
 .. controls (-320.17,-1636.00) and (-312.97,-1634.93) .. (-310.44,-1641.75)
 .. controls (-307.90,-1648.56) and (-310.36,-1681.58) .. (-318.99,-1689.13)
 .. controls (-327.62,-1696.67) and (-387.76,-1733.42) .. (-387.76,-1733.42)
 .. controls (-387.76,-1733.42) and (-428.57,-1703.36) .. (-435.06,-1688.28)
 .. controls (-441.56,-1673.17) and (-450.51,-1654.04) .. (-457.69,-1647.17)
 .. controls (-464.87,-1640.30) and (-478.56,-1647.52) .. (-485.02,-1642.44)
 .. controls (-491.47,-1637.36) and (-490.39,-1636.28) .. cycle
)));
current_src := "Romeo_entrance.th2 [1233]";
string area_border[];
area_border[1] := "l630-6180-10998";
drawoptions();
a_blocks(buildcycle(((-273.40,-1506.45)
 .. controls (-273.40,-1506.45) and (-288.08,-1520.19) .. (-288.52,-1520.86)
 .. controls (-301.15,-1539.99) and (-312.69,-1546.49) .. (-300.10,-1555.50)
 .. controls (-287.50,-1564.50) and (-247.50,-1543.92) .. (-243.18,-1542.49)
 .. controls (-238.86,-1541.05) and (-222.32,-1521.29) .. (-215.47,-1485.99)
 .. controls (-208.63,-1450.71) and (-179.88,-1403.97) .. (-178.42,-1385.96)
 .. controls (-176.97,-1367.94) and (-149.95,-1337.32) .. (-156.79,-1319.32)
 .. controls (-163.63,-1301.32) and (-158.59,-1283.69) .. (-178.03,-1281.51)
 .. controls (-197.45,-1279.34) and (-191.70,-1280.06) .. (-202.49,-1301.29)
 .. controls (-213.29,-1322.52) and (-228.41,-1335.47) .. (-233.09,-1343.75)
 .. controls (-237.77,-1352.03) and (-274.46,-1445.59) .. (-274.46,-1445.59)
 .. controls (-274.46,-1445.59) and (-268.35,-1447.04) .. (-266.19,-1480.53)
 .. controls (-265.82,-1486.32) and (-269.44,-1498.89) .. (-269.44,-1498.89)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [1222]";
string area_border[];
area_border[1] := "l29-9392-18376";
area_border[2] := "l192-7526-13736";
drawoptions();
a_blocks(buildcycle(((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
),
((-94.53,-1004.00)
 .. controls (-92.37,-1004.01) and (-54.93,-989.97) .. (-43.77,-979.53)
 .. controls (-32.61,-969.08) and (-13.16,-954.68) .. (-3.08,-948.20)
 .. controls (6.99,-941.72) and (15.63,-939.92) .. (21.39,-937.41)
 .. controls (27.15,-934.89) and (36.51,-912.92) .. (36.87,-906.08)
 .. controls (37.23,-899.24) and (41.20,-880.52) .. (44.80,-868.28)
 .. controls (48.39,-856.04) and (52.35,-844.53) .. (55.23,-835.89)
 .. controls (58.11,-827.25) and (65.67,-809.25) .. (69.63,-802.05)
 .. controls (73.59,-794.85) and (87.27,-765.33) .. (89.07,-755.25)
 .. controls (90.87,-745.17) and (86.19,-721.05) .. (84.75,-714.93)
 .. controls (83.32,-708.81) and (79.00,-694.05) .. (77.92,-691.89)
)));
current_src := "Romeo_entrance.th2 [1197]";
string area_border[];
area_border[1] := "l184-9852-17572";
area_border[2] := "l30-9984-17468";
drawoptions();
a_blocks(buildcycle(((543.37,-63.40)
 .. controls (541.21,-65.73) and (521.05,-81.21) .. (514.75,-86.60)
 .. controls (508.45,-92.00) and (488.84,-101.53) .. (485.24,-108.37)
 .. controls (481.64,-115.21) and (475.34,-123.85) .. (473.00,-130.32)
 .. controls (470.66,-136.80) and (472.27,-147.78) .. (471.19,-153.00)
 .. controls (470.11,-158.22) and (470.29,-165.60) .. (466.51,-176.39)
 .. controls (462.73,-187.19) and (454.81,-200.33) .. (453.01,-207.70)
 .. controls (451.21,-215.08) and (442.93,-222.64) .. (440.05,-229.84)
 .. controls (437.17,-237.04) and (427.81,-250.00) .. (424.75,-253.61)
 .. controls (421.69,-257.21) and (395.96,-283.50) .. (392.36,-290.34)
 .. controls (388.76,-297.18) and (367.88,-324.90) .. (363.74,-330.12)
 .. controls (359.60,-335.34) and (351.50,-351.17) .. (348.62,-358.01)
 .. controls (345.74,-364.85) and (344.48,-367.37) .. (338.90,-372.23)
 .. controls (333.32,-377.09) and (327.38,-383.93) .. (322.52,-390.05)
 .. controls (317.66,-396.17) and (310.28,-407.87) .. (309.38,-412.73)
 .. controls (308.48,-417.59) and (306.68,-428.57) .. (306.14,-433.25)
),
((-77.80,-1335.57)
 .. controls (-73.66,-1326.93) and (-80.85,-1310.36) .. (-72.93,-1290.19)
 .. controls (-65.01,-1270.03) and (-54.93,-1252.02) .. (-58.53,-1230.43)
 .. controls (-62.13,-1208.83) and (-65.02,-1182.20) .. (-68.62,-1171.41)
 .. controls (-72.23,-1160.62) and (-71.50,-1138.29) .. (-70.78,-1125.33)
 .. controls (-70.05,-1112.36) and (-71.48,-1088.60) .. (-59.96,-1071.32)
 .. controls (-48.44,-1054.04) and (-34.76,-1019.48) .. (-14.60,-1003.64)
 .. controls (5.56,-987.79) and (46.59,-945.33) .. (53.79,-932.37)
 .. controls (60.99,-919.40) and (97.72,-886.27) .. (103.48,-873.31)
 .. controls (109.24,-860.36) and (132.28,-816.44) .. (135.88,-804.93)
 .. controls (139.47,-793.41) and (145.94,-724.30) .. (187.71,-693.33)
 .. controls (229.47,-662.38) and (229.47,-624.94) .. (235.23,-614.86)
 .. controls (240.99,-604.78) and (243.87,-552.23) .. (243.87,-547.91)
 .. controls (243.87,-543.59) and (246.03,-519.83) .. (254.67,-504.71)
 .. controls (263.31,-489.59) and (278.42,-468.71) .. (285.62,-457.91)
 .. controls (292.82,-447.11) and (309.38,-415.43) .. (315.14,-408.95)
 .. controls (320.90,-402.47) and (347.54,-384.47) .. (356.18,-374.39)
 .. controls (364.82,-364.31) and (438.26,-284.39) .. (444.74,-272.15)
 .. controls (451.21,-259.90) and (456.97,-236.86) .. (461.29,-225.34)
 .. controls (465.61,-213.82) and (477.13,-203.75) .. (483.61,-194.39)
 .. controls (490.09,-185.04) and (510.97,-159.13) .. (510.97,-148.33)
 .. controls (510.97,-137.53) and (519.61,-108.02) .. (529.69,-91.47)
 .. controls (539.77,-74.91) and (544.10,-36.03) .. (544.10,-30.27)
 .. controls (544.10,-24.51) and (549.86,23.73) .. (547.70,35.97)
 .. controls (545.54,48.21) and (537.62,71.26) .. (546.26,90.69)
 .. controls (554.90,110.13) and (570.02,138.93) .. (576.50,150.45)
 .. controls (582.98,161.96) and (598.81,189.31) .. (597.37,201.55)
 .. controls (595.93,213.79) and (593.95,235.92) .. (568.03,243.14)
 .. controls (542.12,250.36) and (505.94,254.15) .. (493.70,253.43)
 .. controls (481.46,252.71) and (452.67,247.68) .. (437.55,266.41)
 .. controls (422.43,285.13) and (419.54,281.53) .. (417.38,287.29)
)));
current_src := "Romeo_entrance.th2 [1192]";
string area_border[];
area_border[1] := "l29-9392-18376";
area_border[2] := "l183-9896-18512";
drawoptions();
a_blocks(buildcycle(((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
),
((391.46,-161.81)
 .. controls (394.52,-159.29) and (405.50,-152.45) .. (409.64,-145.43)
 .. controls (413.78,-138.41) and (415.94,-124.73) .. (418.82,-116.26)
 .. controls (421.70,-107.80) and (425.12,-107.27) .. (431.78,-103.85)
 .. controls (438.44,-100.43) and (454.64,-86.40) .. (458.96,-82.80)
 .. controls (463.28,-79.21) and (482.00,-56.35) .. (485.96,-50.23)
 .. controls (489.92,-44.11) and (503.24,-20.17) .. (505.58,-8.47)
 .. controls (507.92,3.23) and (506.30,49.13) .. (505.22,53.45)
 .. controls (504.14,57.77) and (500.90,71.63) .. (499.28,83.87)
 .. controls (497.66,96.12) and (490.28,121.51) .. (487.22,127.45)
 .. controls (484.16,133.40) and (474.80,141.32) .. (467.24,143.66)
 .. controls (459.68,146.00) and (446.90,131.77) .. (443.84,128.53)
 .. controls (440.78,125.28) and (431.60,111.60) .. (429.62,106.92)
 .. controls (427.64,102.24) and (415.04,93.41) .. (413.60,92.15)
)));
current_src := "Romeo_entrance.th2 [1107]";
string area_border[];
area_border[1] := "l601-8802-24326";
area_border[2] := "l173-10224-23120";
area_border[3] := "l602-9962-22858";
area_border[4] := "l169-9400-20832";
area_border[5] := "l603-8850-20564";
area_border[6] := "l163-9132-20000";
area_border[7] := "l604-9758-20332";
area_border[8] := "l597-10410-22954";
drawoptions();
a_water(buildcycle(((312.81,1124.43)
 .. controls (312.81,1124.43) and (294.37,1075.83) .. (326.81,1072.42)
 .. controls (359.26,1069.01) and (362.88,1066.39) .. (362.88,1066.39)
),
((519.54,864.09)
 .. controls (521.88,864.82) and (527.64,868.62) .. (531.61,870.43)
 .. controls (535.57,872.25) and (548.00,882.00) .. (550.34,884.34)
 .. controls (552.68,886.69) and (562.23,897.71) .. (566.38,903.14)
 .. controls (570.52,908.56) and (577.01,920.29) .. (579.53,924.97)
 .. controls (582.05,929.65) and (589.94,945.40) .. (591.74,948.25)
 .. controls (593.53,951.10) and (596.01,972.56) .. (596.54,977.57)
 .. controls (597.08,982.59) and (596.17,997.14) .. (596.17,1005.43)
 .. controls (596.18,1013.73) and (593.65,1015.34) .. (592.75,1017.86)
 .. controls (591.85,1020.38) and (596.73,1022.22) .. (597.63,1023.14)
 .. controls (598.53,1024.05) and (612.62,1029.26) .. (613.88,1029.63)
 .. controls (615.15,1030.00) and (619.48,1030.58) .. (621.64,1032.05)
 .. controls (623.81,1033.51) and (625.62,1036.42) .. (626.16,1037.32)
 .. controls (626.70,1038.23) and (624.54,1042.19) .. (624.00,1043.99)
 .. controls (623.46,1045.79) and (620.39,1055.09) .. (620.38,1058.30)
 .. controls (620.37,1061.51) and (617.08,1072.65) .. (613.99,1077.23)
 .. controls (610.90,1081.80) and (605.43,1083.65) .. (593.72,1094.12)
 .. controls (581.96,1104.63) and (564.61,1115.33) .. (558.34,1117.79)
 .. controls (552.07,1120.25) and (542.94,1123.83) .. (538.81,1126.41)
 .. controls (534.69,1128.99) and (532.89,1129.53) .. (530.37,1130.25)
 .. controls (527.85,1130.96) and (528.37,1126.94) .. (526.92,1124.91)
 .. controls (525.47,1122.89) and (518.21,1112.58) .. (512.03,1100.34)
 .. controls (505.90,1088.19) and (495.08,1087.26) .. (491.12,1085.82)
 .. controls (487.16,1084.38) and (471.16,1080.30) .. (464.51,1078.03)
 .. controls (457.88,1075.75) and (444.07,1070.91) .. (439.22,1070.60)
 .. controls (434.38,1070.30) and (418.05,1066.52) .. (415.89,1065.82)
 .. controls (413.74,1065.11) and (402.76,1063.69) .. (400.06,1063.32)
 .. controls (397.35,1062.95) and (373.00,1060.59) .. (370.83,1060.21)
 .. controls (368.67,1059.83) and (362.88,1066.39) .. (362.88,1066.39)
),
((519.54,864.09)
 -- (485.52,783.45)
),
((322.49,457.09)
 .. controls (324.29,455.30) and (345.00,454.08) .. (353.64,454.64)
 .. controls (362.28,455.19) and (390.90,465.81) .. (397.38,470.29)
 .. controls (403.86,474.78) and (418.07,489.85) .. (422.93,494.88)
 .. controls (427.78,499.91) and (456.22,528.51) .. (459.46,532.12)
 .. controls (462.70,535.72) and (488.10,569.46) .. (491.53,578.48)
 .. controls (494.95,587.48) and (498.37,596.84) .. (498.01,601.33)
 .. controls (497.64,605.82) and (506.63,629.18) .. (508.24,634.74)
 .. controls (509.86,640.32) and (513.46,664.44) .. (515.08,668.59)
 .. controls (516.71,672.74) and (517.80,700.18) .. (516.37,704.33)
 .. controls (514.93,708.48) and (508.81,725.93) .. (507.54,729.88)
 .. controls (506.28,733.83) and (500.14,749.96) .. (498.33,753.36)
 .. controls (496.53,756.76) and (491.83,768.58) .. (490.03,769.83)
 .. controls (488.23,771.08) and (485.52,783.45) .. (485.52,783.45)
),
((322.49,457.09)
 -- (274.08,341.88)
),
((274.08,341.88)
 -- (447.61,329.72)
),
((447.61,329.72)
 -- (533.27,526.20)
 -- (593.36,660.72)
 -- (594.44,791.47)
 -- (588.01,841.14)
),
((312.81,1124.43)
 .. controls (312.81,1124.43) and (377.16,1061.66) .. (450.99,1097.20)
 .. controls (525.53,1133.09) and (510.29,1152.21) .. (549.46,1142.52)
 .. controls (588.60,1132.83) and (629.28,1085.59) .. (635.08,1074.65)
 .. controls (640.91,1063.67) and (659.21,1013.75) .. (642.24,985.58)
 .. controls (625.35,957.53) and (620.68,906.17) .. (607.02,891.85)
 .. controls (593.36,877.52) and (591.24,851.37) .. (588.01,841.14)
)));
current_src := "Romeo_entrance.th2 [1059]";
string area_border[];
area_border[1] := "l241-3598-7320";
area_border[2] := "l96-3588-7456";
drawoptions();
a_water(buildcycle(((-670.58,-1904.14)
 .. controls (-670.58,-1904.14) and (-672.10,-1923.72) .. (-671.83,-1932.13)
 .. controls (-671.57,-1940.56) and (-671.66,-1944.99) .. (-667.73,-1950.81)
 .. controls (-663.81,-1956.62) and (-659.81,-1960.53) .. (-655.44,-1962.27)
 .. controls (-651.08,-1964.00) and (-645.29,-1963.58) .. (-642.77,-1959.26)
 .. controls (-640.25,-1954.96) and (-639.55,-1948.85) .. (-634.19,-1947.12)
 .. controls (-628.84,-1945.40) and (-624.94,-1942.62) .. (-618.54,-1941.67)
 .. controls (-612.15,-1940.74) and (-605.04,-1941.24) .. (-601.90,-1934.55)
 .. controls (-598.74,-1927.84) and (-593.06,-1923.65) .. (-589.85,-1917.23)
 .. controls (-586.62,-1910.76) and (-585.87,-1904.23) .. (-585.87,-1904.23)
),
((-512.58,-1755.52)
 .. controls (-509.71,-1754.80) and (-506.13,-1763.12) .. (-505.97,-1767.46)
 .. controls (-505.80,-1771.80) and (-507.27,-1784.99) .. (-506.74,-1788.06)
 .. controls (-506.21,-1791.13) and (-500.27,-1803.92) .. (-499.19,-1808.23)
 .. controls (-498.11,-1812.55) and (-509.23,-1829.06) .. (-512.28,-1834.25)
 .. controls (-515.32,-1839.45) and (-528.27,-1855.09) .. (-532.60,-1862.12)
 .. controls (-536.92,-1869.14) and (-548.58,-1875.91) .. (-556.29,-1880.92)
 .. controls (-564.03,-1885.94) and (-571.63,-1896.28) .. (-575.61,-1899.91)
 .. controls (-579.59,-1903.54) and (-594.66,-1912.65) .. (-599.47,-1914.73)
 .. controls (-604.27,-1916.80) and (-630.55,-1921.17) .. (-646.54,-1925.79)
 .. controls (-662.68,-1930.45) and (-662.82,-1925.80) .. (-665.67,-1923.96)
 .. controls (-668.52,-1922.11) and (-671.33,-1913.91) .. (-672.21,-1910.63)
)));
current_src := "Romeo_entrance.th2 [1050]";
string area_border[];
area_border[1] := "l259-2880-6384";
area_border[2] := "l240-2678-6802";
area_border[3] := "l107-2658-7064";
area_border[4] := "l239-2820-7090";
area_border[5] := "l260-3396-6065";
area_border[6] := "l29-3238-5890";
drawoptions();
a_water(buildcycle(((-784.78,-2051.57)
 .. controls (-782.11,-2049.49) and (-776.59,-2047.64) .. (-770.39,-2047.62)
 .. controls (-764.37,-2047.60) and (-765.31,-2049.44) .. (-757.03,-2047.86)
 .. controls (-748.81,-2046.30) and (-751.59,-2049.48) .. (-750.48,-2052.40)
 .. controls (-749.36,-2055.35) and (-750.70,-2061.51) .. (-750.93,-2067.04)
 .. controls (-751.15,-2072.72) and (-753.83,-2091.35) .. (-754.27,-2094.49)
 .. controls (-754.71,-2097.64) and (-763.06,-2145.64) .. (-765.11,-2157.38)
 .. controls (-767.11,-2168.82) and (-765.59,-2196.14) .. (-764.51,-2200.64)
),
((-800.50,-1982.20)
 .. controls (-800.50,-1982.20) and (-796.84,-2006.23) .. (-794.25,-2013.11)
 .. controls (-791.71,-2019.87) and (-784.78,-2030.96) .. (-780.00,-2035.51)
 .. controls (-775.12,-2040.15) and (-764.00,-2052.21) .. (-762.08,-2053.73)
),
((-725.57,-1941.40)
 .. controls (-727.74,-1948.26) and (-744.88,-1958.52) .. (-750.06,-1958.79)
 .. controls (-755.22,-1959.06) and (-774.12,-1958.31) .. (-778.73,-1960.18)
 .. controls (-783.33,-1962.05) and (-795.04,-1983.81) .. (-798.09,-1988.10)
 .. controls (-801.16,-1992.41) and (-806.46,-1998.75) .. (-809.82,-2001.52)
 .. controls (-813.21,-2004.32) and (-826.51,-2014.69) .. (-828.52,-2015.66)
),
((-795.91,-1975.78)
 .. controls (-795.91,-1975.78) and (-791.72,-1978.41) .. (-785.72,-1978.38)
 .. controls (-779.75,-1978.35) and (-766.72,-1981.62) .. (-759.57,-1980.66)
 .. controls (-752.43,-1979.70) and (-743.24,-1981.46) .. (-736.93,-1984.44)
 .. controls (-730.61,-1987.42) and (-721.44,-1992.75) .. (-714.48,-1990.69)
 .. controls (-707.30,-1988.56) and (-697.99,-1985.73) .. (-689.27,-1996.64)
 .. controls (-680.62,-2007.46) and (-679.54,-2012.04) .. (-673.97,-2016.80)
 .. controls (-668.40,-2021.57) and (-671.86,-2025.97) .. (-643.86,-2030.83)
 .. controls (-615.91,-2035.69) and (-606.96,-2039.41) .. (-605.53,-2038.71)
),
((-676.94,-2196.59)
 .. controls (-675.68,-2192.27) and (-670.98,-2177.07) .. (-666.01,-2169.33)
 .. controls (-661.01,-2161.54) and (-650.92,-2142.57) .. (-647.94,-2137.73)
 .. controls (-644.97,-2132.90) and (-629.07,-2103.25) .. (-627.79,-2100.33)
 .. controls (-626.50,-2097.42) and (-621.15,-2070.78) .. (-615.30,-2050.56)
 .. controls (-609.50,-2030.48) and (-616.15,-2008.59) .. (-617.07,-2006.28)
 .. controls (-617.99,-2003.97) and (-619.57,-1988.89) .. (-619.24,-1985.70)
 .. controls (-618.91,-1982.51) and (-612.59,-1969.81) .. (-611.21,-1965.58)
 .. controls (-609.82,-1961.35) and (-601.59,-1948.74) .. (-597.00,-1944.58)
),
((-767.75,-2196.14)
 .. controls (-766.31,-2198.84) and (-761.63,-2202.61) .. (-759.27,-2204.02)
 .. controls (-756.91,-2205.43) and (-752.54,-2207.33) .. (-750.17,-2207.11)
 .. controls (-747.81,-2206.89) and (-746.53,-2207.76) .. (-741.07,-2204.60)
 .. controls (-735.61,-2201.44) and (-727.08,-2200.24) .. (-725.62,-2196.62)
 .. controls (-724.16,-2192.98) and (-721.90,-2193.48) .. (-720.92,-2192.98)
 .. controls (-719.48,-2192.26) and (-716.53,-2192.64) .. (-714.48,-2194.49)
 .. controls (-713.06,-2195.78) and (-710.09,-2198.70) .. (-709.15,-2200.54)
 .. controls (-707.19,-2204.36) and (-706.30,-2206.17) .. (-702.20,-2206.24)
 .. controls (-698.11,-2206.31) and (-695.08,-2204.22) .. (-691.17,-2202.31)
 .. controls (-687.25,-2200.39) and (-684.39,-2199.35) .. (-681.88,-2198.10)
 .. controls (-679.37,-2196.86) and (-673.79,-2195.24) .. (-673.79,-2195.24)
)));
current_src := "Romeo_entrance.th2 [1016]";
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
a_blocks(buildcycle(((-540.12,-1858.83)
 .. controls (-540.12,-1858.83) and (-527.99,-1879.13) .. (-527.97,-1889.92)
 .. controls (-527.95,-1900.66) and (-524.61,-1918.17) .. (-524.61,-1918.17)
),
((-597.00,-1944.58)
 .. controls (-594.89,-1941.95) and (-590.31,-1936.00) .. (-585.51,-1932.67)
 .. controls (-580.69,-1929.33) and (-572.62,-1926.66) .. (-567.93,-1925.92)
 .. controls (-563.23,-1925.18) and (-543.52,-1917.47) .. (-540.28,-1915.67)
 .. controls (-537.04,-1913.87) and (-519.29,-1903.54) .. (-514.81,-1899.25)
 .. controls (-510.32,-1894.95) and (-502.22,-1875.86) .. (-499.68,-1868.81)
 .. controls (-497.14,-1861.77) and (-491.75,-1846.48) .. (-490.68,-1841.10)
 .. controls (-489.62,-1835.73) and (-488.39,-1822.28) .. (-487.49,-1817.42)
 .. controls (-486.59,-1812.56) and (-482.98,-1803.54) .. (-480.27,-1798.31)
 .. controls (-477.57,-1793.08) and (-469.08,-1783.13) .. (-462.40,-1777.70)
 .. controls (-455.72,-1772.27) and (-441.83,-1763.22) .. (-438.04,-1761.06)
 .. controls (-434.26,-1758.89) and (-425.43,-1750.59) .. (-422.72,-1746.81)
 .. controls (-420.02,-1743.03) and (-410.12,-1730.42) .. (-406.51,-1727.72)
 .. controls (-402.91,-1725.01) and (-390.48,-1710.23) .. (-386.69,-1707.53)
 .. controls (-382.91,-1704.82) and (-367.60,-1691.31) .. (-359.68,-1682.67)
 .. controls (-351.77,-1674.04) and (-341.34,-1665.06) .. (-335.04,-1662.37)
 .. controls (-328.75,-1659.68) and (-308.09,-1646.05) .. (-304.13,-1642.46)
 .. controls (-300.18,-1638.88) and (-272.67,-1617.86) .. (-266.37,-1612.64)
 .. controls (-260.07,-1607.42) and (-240.99,-1592.66) .. (-234.69,-1587.81)
 .. controls (-228.40,-1582.95) and (-191.93,-1545.98) .. (-187.61,-1542.02)
 .. controls (-183.29,-1538.07) and (-177.53,-1520.25) .. (-174.65,-1512.14)
 .. controls (-171.76,-1504.03) and (-157.69,-1480.59) .. (-155.71,-1476.45)
 .. controls (-153.73,-1472.30) and (-131.95,-1430.55) .. (-128.71,-1425.51)
 .. controls (-125.47,-1420.47) and (-116.29,-1409.14) .. (-113.77,-1405.18)
 .. controls (-111.25,-1401.22) and (-90.93,-1371.01) .. (-89.49,-1364.36)
 .. controls (-88.06,-1357.71) and (-79.42,-1340.62) .. (-77.80,-1335.57)
),
((-676.94,-2196.59)
 .. controls (-675.68,-2192.27) and (-670.98,-2177.07) .. (-666.01,-2169.33)
 .. controls (-661.01,-2161.54) and (-650.92,-2142.57) .. (-647.94,-2137.73)
 .. controls (-644.97,-2132.90) and (-629.07,-2103.25) .. (-627.79,-2100.33)
 .. controls (-626.50,-2097.42) and (-621.15,-2070.78) .. (-615.30,-2050.56)
 .. controls (-609.50,-2030.48) and (-616.15,-2008.59) .. (-617.07,-2006.28)
 .. controls (-617.99,-2003.97) and (-619.57,-1988.89) .. (-619.24,-1985.70)
 .. controls (-618.91,-1982.51) and (-612.59,-1969.81) .. (-611.21,-1965.58)
 .. controls (-609.82,-1961.35) and (-601.59,-1948.74) .. (-597.00,-1944.58)
),
((-795.91,-1975.78)
 .. controls (-795.91,-1975.78) and (-791.72,-1978.41) .. (-785.72,-1978.38)
 .. controls (-779.75,-1978.35) and (-766.72,-1981.62) .. (-759.57,-1980.66)
 .. controls (-752.43,-1979.70) and (-743.24,-1981.46) .. (-736.93,-1984.44)
 .. controls (-730.61,-1987.42) and (-721.44,-1992.75) .. (-714.48,-1990.69)
 .. controls (-707.30,-1988.56) and (-697.99,-1985.73) .. (-689.27,-1996.64)
 .. controls (-680.62,-2007.46) and (-679.54,-2012.04) .. (-673.97,-2016.80)
 .. controls (-668.40,-2021.57) and (-671.86,-2025.97) .. (-643.86,-2030.83)
 .. controls (-615.91,-2035.69) and (-606.96,-2039.41) .. (-605.53,-2038.71)
),
((-725.57,-1941.40)
 .. controls (-727.74,-1948.26) and (-744.88,-1958.52) .. (-750.06,-1958.79)
 .. controls (-755.22,-1959.06) and (-774.12,-1958.31) .. (-778.73,-1960.18)
 .. controls (-783.33,-1962.05) and (-795.04,-1983.81) .. (-798.09,-1988.10)
 .. controls (-801.16,-1992.41) and (-806.46,-1998.75) .. (-809.82,-2001.52)
 .. controls (-813.21,-2004.32) and (-826.51,-2014.69) .. (-828.52,-2015.66)
),
((-758.87,-1952.92)
 .. controls (-758.87,-1952.92) and (-739.71,-1962.63) .. (-727.26,-1966.44)
 .. controls (-714.73,-1970.28) and (-690.35,-1977.10) .. (-680.82,-1979.31)
 .. controls (-671.25,-1981.54) and (-662.34,-1988.25) .. (-658.73,-1979.26)
 .. controls (-655.10,-1970.20) and (-652.52,-1956.80) .. (-652.52,-1956.80)
),
((-670.58,-1904.14)
 .. controls (-670.58,-1904.14) and (-672.10,-1923.72) .. (-671.83,-1932.13)
 .. controls (-671.57,-1940.56) and (-671.66,-1944.99) .. (-667.73,-1950.81)
 .. controls (-663.81,-1956.62) and (-659.81,-1960.53) .. (-655.44,-1962.27)
 .. controls (-651.08,-1964.00) and (-645.29,-1963.58) .. (-642.77,-1959.26)
 .. controls (-640.25,-1954.96) and (-639.55,-1948.85) .. (-634.19,-1947.12)
 .. controls (-628.84,-1945.40) and (-624.94,-1942.62) .. (-618.54,-1941.67)
 .. controls (-612.15,-1940.74) and (-605.04,-1941.24) .. (-601.90,-1934.55)
 .. controls (-598.74,-1927.84) and (-593.06,-1923.65) .. (-589.85,-1917.23)
 .. controls (-586.62,-1910.76) and (-585.87,-1904.23) .. (-585.87,-1904.23)
),
((-512.58,-1755.52)
 .. controls (-509.71,-1754.80) and (-506.13,-1763.12) .. (-505.97,-1767.46)
 .. controls (-505.80,-1771.80) and (-507.27,-1784.99) .. (-506.74,-1788.06)
 .. controls (-506.21,-1791.13) and (-500.27,-1803.92) .. (-499.19,-1808.23)
 .. controls (-498.11,-1812.55) and (-509.23,-1829.06) .. (-512.28,-1834.25)
 .. controls (-515.32,-1839.45) and (-528.27,-1855.09) .. (-532.60,-1862.12)
 .. controls (-536.92,-1869.14) and (-548.58,-1875.91) .. (-556.29,-1880.92)
 .. controls (-564.03,-1885.94) and (-571.63,-1896.28) .. (-575.61,-1899.91)
 .. controls (-579.59,-1903.54) and (-594.66,-1912.65) .. (-599.47,-1914.73)
 .. controls (-604.27,-1916.80) and (-630.55,-1921.17) .. (-646.54,-1925.79)
 .. controls (-662.68,-1930.45) and (-662.82,-1925.80) .. (-665.67,-1923.96)
 .. controls (-668.52,-1922.11) and (-671.33,-1913.91) .. (-672.21,-1910.63)
)));
current_src := "Romeo_entrance.th2 [999]";
string area_border[];
area_border[1] := "l249-4050-7530";
area_border[2] := "l54-5320-8936";
area_border[3] := "l248-3948-7524";
area_border[4] := "l96-3588-7456";
drawoptions();
a_debris(buildcycle(((-569.22,-1883.22)
 -- (-539.71,-1925.34)
),
((-597.00,-1944.58)
 .. controls (-594.89,-1941.95) and (-590.31,-1936.00) .. (-585.51,-1932.67)
 .. controls (-580.69,-1929.33) and (-572.62,-1926.66) .. (-567.93,-1925.92)
 .. controls (-563.23,-1925.18) and (-543.52,-1917.47) .. (-540.28,-1915.67)
 .. controls (-537.04,-1913.87) and (-519.29,-1903.54) .. (-514.81,-1899.25)
 .. controls (-510.32,-1894.95) and (-502.22,-1875.86) .. (-499.68,-1868.81)
 .. controls (-497.14,-1861.77) and (-491.75,-1846.48) .. (-490.68,-1841.10)
 .. controls (-489.62,-1835.73) and (-488.39,-1822.28) .. (-487.49,-1817.42)
 .. controls (-486.59,-1812.56) and (-482.98,-1803.54) .. (-480.27,-1798.31)
 .. controls (-477.57,-1793.08) and (-469.08,-1783.13) .. (-462.40,-1777.70)
 .. controls (-455.72,-1772.27) and (-441.83,-1763.22) .. (-438.04,-1761.06)
 .. controls (-434.26,-1758.89) and (-425.43,-1750.59) .. (-422.72,-1746.81)
 .. controls (-420.02,-1743.03) and (-410.12,-1730.42) .. (-406.51,-1727.72)
 .. controls (-402.91,-1725.01) and (-390.48,-1710.23) .. (-386.69,-1707.53)
 .. controls (-382.91,-1704.82) and (-367.60,-1691.31) .. (-359.68,-1682.67)
 .. controls (-351.77,-1674.04) and (-341.34,-1665.06) .. (-335.04,-1662.37)
 .. controls (-328.75,-1659.68) and (-308.09,-1646.05) .. (-304.13,-1642.46)
 .. controls (-300.18,-1638.88) and (-272.67,-1617.86) .. (-266.37,-1612.64)
 .. controls (-260.07,-1607.42) and (-240.99,-1592.66) .. (-234.69,-1587.81)
 .. controls (-228.40,-1582.95) and (-191.93,-1545.98) .. (-187.61,-1542.02)
 .. controls (-183.29,-1538.07) and (-177.53,-1520.25) .. (-174.65,-1512.14)
 .. controls (-171.76,-1504.03) and (-157.69,-1480.59) .. (-155.71,-1476.45)
 .. controls (-153.73,-1472.30) and (-131.95,-1430.55) .. (-128.71,-1425.51)
 .. controls (-125.47,-1420.47) and (-116.29,-1409.14) .. (-113.77,-1405.18)
 .. controls (-111.25,-1401.22) and (-90.93,-1371.01) .. (-89.49,-1364.36)
 .. controls (-88.06,-1357.71) and (-79.42,-1340.62) .. (-77.80,-1335.57)
),
((-573.93,-1889.73)
 -- (-564.64,-1933.40)
),
((-512.58,-1755.52)
 .. controls (-509.71,-1754.80) and (-506.13,-1763.12) .. (-505.97,-1767.46)
 .. controls (-505.80,-1771.80) and (-507.27,-1784.99) .. (-506.74,-1788.06)
 .. controls (-506.21,-1791.13) and (-500.27,-1803.92) .. (-499.19,-1808.23)
 .. controls (-498.11,-1812.55) and (-509.23,-1829.06) .. (-512.28,-1834.25)
 .. controls (-515.32,-1839.45) and (-528.27,-1855.09) .. (-532.60,-1862.12)
 .. controls (-536.92,-1869.14) and (-548.58,-1875.91) .. (-556.29,-1880.92)
 .. controls (-564.03,-1885.94) and (-571.63,-1896.28) .. (-575.61,-1899.91)
 .. controls (-579.59,-1903.54) and (-594.66,-1912.65) .. (-599.47,-1914.73)
 .. controls (-604.27,-1916.80) and (-630.55,-1921.17) .. (-646.54,-1925.79)
 .. controls (-662.68,-1930.45) and (-662.82,-1925.80) .. (-665.67,-1923.96)
 .. controls (-668.52,-1922.11) and (-671.33,-1913.91) .. (-672.21,-1910.63)
)));
current_src := "Romeo_entrance.th2 [973]";
string area_border[];
area_border[1] := "l688-3876-8270";
drawoptions();
a_debris(buildcycle(((-648.89,-1765.99)
 -- (-619.93,-1809.13)
 -- (-580.57,-1774.96)
 -- (-618.14,-1737.52)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [872]";
string area_border[];
area_border[1] := "l611-4190-8982";
area_border[2] := "l252-4140-8522";
area_border[3] := "l609-4168-8172";
area_border[4] := "l620-4610-8624";
area_border[5] := "l610-4496-8810";
area_border[6] := "l614-4454-8846";
drawoptions();
a_water(buildcycle(((-484.72,-1663.78)
 .. controls (-484.72,-1663.78) and (-497.94,-1638.07) .. (-516.62,-1642.68)
 .. controls (-535.28,-1647.28) and (-681.28,-1823.73) .. (-681.28,-1823.73)
),
((-681.28,-1823.73)
 .. controls (-681.28,-1823.73) and (-683.38,-1843.78) .. (-649.55,-1858.40)
 .. controls (-642.93,-1861.26) and (-634.04,-1855.00) .. (-628.87,-1852.24)
 .. controls (-611.72,-1843.09) and (-602.42,-1834.90) .. (-602.42,-1834.90)
),
((-602.42,-1834.90)
 -- (-540.12,-1858.83)
 .. controls (-540.12,-1858.83) and (-544.10,-1910.32) .. (-525.65,-1925.31)
 .. controls (-507.22,-1940.30) and (-405.42,-1737.78) .. (-405.42,-1737.78)
 .. controls (-405.42,-1737.78) and (-418.21,-1728.72) .. (-425.66,-1706.58)
 .. controls (-428.55,-1697.96) and (-443.36,-1694.79) .. (-448.77,-1699.85)
),
((-468.59,-1684.77)
 .. controls (-468.59,-1684.77) and (-487.97,-1712.75) .. (-471.39,-1727.84)
 .. controls (-454.81,-1742.92) and (-445.87,-1706.66) .. (-448.77,-1699.85)
),
((-468.59,-1684.77)
 -- (-471.09,-1674.30)
),
((-484.72,-1663.78)
 .. controls (-484.72,-1663.78) and (-485.58,-1674.48) .. (-471.09,-1674.30)
)));
current_src := "Romeo_entrance.th2 [579]";
string area_border[];
area_border[1] := "l684-11582-29882";
drawoptions();
a_sand(buildcycle(((685.20,2121.38)
 .. controls (685.20,2121.38) and (776.66,2179.78) .. (780.24,2116.00)
 .. controls (783.83,2052.21) and (827.77,2160.32) .. (827.77,2160.32)
 -- (694.22,2207.49)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [524]";
string area_border[];
area_border[1] := "l638-10708-27500";
area_border[2] := "l209-10984-27732";
area_border[3] := "l643-11124-27794";
area_border[4] := "l640-11146-27756";
area_border[5] := "l211-10474-26546";
area_border[6] := "l213-10126-26710";
area_border[7] := "l638-10708-27500";
drawoptions();
a_water(buildcycle(((538.11,1594.30)
 -- (677.36,1708.50)
),
((711.43,1741.59)
 .. controls (711.43,1741.59) and (708.87,1740.74) .. (706.35,1738.95)
 .. controls (703.83,1737.16) and (705.28,1735.92) .. (702.59,1731.80)
 .. controls (699.89,1727.69) and (694.85,1724.62) .. (691.97,1722.10)
 .. controls (689.08,1719.57) and (687.10,1717.94) .. (685.66,1715.77)
 .. controls (684.22,1713.61) and (679.71,1709.78) .. (677.36,1708.50)
),
((725.79,1738.06)
 .. controls (718.52,1738.07) and (711.43,1741.59) .. (711.43,1741.59)
),
((631.51,1474.30)
 -- (734.27,1589.42)
 -- (725.79,1738.06)
),
((541.38,1487.53)
 .. controls (541.38,1487.53) and (540.99,1490.00) .. (544.34,1496.21)
 .. controls (547.69,1502.42) and (552.51,1511.95) .. (556.21,1514.47)
 .. controls (559.89,1516.97) and (565.64,1520.35) .. (572.75,1520.45)
 .. controls (579.72,1520.55) and (595.13,1520.71) .. (599.99,1515.64)
 .. controls (604.84,1510.57) and (612.23,1503.61) .. (615.20,1500.51)
 .. controls (618.17,1497.42) and (623.57,1489.22) .. (625.82,1486.51)
 .. controls (628.07,1483.80) and (631.51,1474.30) .. (631.51,1474.30)
),
((538.11,1594.30)
 .. controls (538.11,1594.30) and (529.16,1584.78) .. (527.46,1576.14)
 .. controls (525.74,1567.43) and (520.55,1563.96) .. (527.07,1558.38)
 .. controls (533.55,1552.84) and (534.02,1555.78) .. (538.97,1549.47)
 .. controls (543.97,1543.10) and (545.11,1539.83) .. (545.57,1532.90)
 .. controls (546.03,1525.93) and (546.78,1524.70) .. (550.92,1521.03)
 .. controls (555.06,1517.35) and (559.20,1513.26) .. (559.20,1513.26)
),
((538.11,1594.30)
 -- (677.36,1708.50)
)));
current_src := "Romeo_entrance.th2 [388]";
string area_border[];
area_border[1] := "l648-10804-28026";
area_border[2] := "l210-10833-28559";
area_border[3] := "l650-11042-28484";
area_border[4] := "l208-11076-27806";
area_border[5] := "l209-10984-27732";
drawoptions();
a_blocks(buildcycle(((643.42,1900.60)
 -- (677.36,1708.50)
),
((643.42,1900.60)
 .. controls (645.76,1898.44) and (653.32,1886.39) .. (654.76,1884.24)
 .. controls (656.20,1882.08) and (658.21,1878.94) .. (662.86,1876.52)
 .. controls (670.43,1872.57) and (662.87,1873.65) .. (674.38,1876.52)
 .. controls (677.98,1877.42) and (684.10,1875.43) .. (688.96,1876.68)
 .. controls (693.81,1877.93) and (700.65,1882.42) .. (700.65,1882.42)
),
((716.22,1780.42)
 .. controls (716.22,1780.42) and (716.82,1839.68) .. (700.65,1882.42)
),
((716.22,1780.42)
 .. controls (716.22,1780.42) and (713.17,1782.24) .. (708.49,1780.98)
 .. controls (703.81,1779.73) and (700.75,1777.75) .. (699.49,1771.07)
 .. controls (698.22,1764.40) and (697.86,1759.35) .. (699.66,1755.22)
 .. controls (701.47,1751.10) and (704.17,1748.42) .. (707.06,1745.38)
 .. controls (709.94,1742.35) and (713.56,1738.61) .. (718.24,1738.61)
 .. controls (722.92,1738.61) and (725.79,1738.06) .. (725.79,1738.06)
),
((711.43,1741.59)
 .. controls (711.43,1741.59) and (708.87,1740.74) .. (706.35,1738.95)
 .. controls (703.83,1737.16) and (705.28,1735.92) .. (702.59,1731.80)
 .. controls (699.89,1727.69) and (694.85,1724.62) .. (691.97,1722.10)
 .. controls (689.08,1719.57) and (687.10,1717.94) .. (685.66,1715.77)
 .. controls (684.22,1713.61) and (679.71,1709.78) .. (677.36,1708.50)
)));
current_src := "Romeo_entrance.th2 [340]";
string area_border[];
area_border[1] := "l210-10833-28559";
area_border[2] := "l646-10658-28742";
area_border[3] := "l213-10786-29310";
area_border[4] := "l645-11004-29038";
drawoptions();
a_water(buildcycle(((643.42,1900.60)
 .. controls (645.76,1898.44) and (653.32,1886.39) .. (654.76,1884.24)
 .. controls (656.20,1882.08) and (658.21,1878.94) .. (662.86,1876.52)
 .. controls (670.43,1872.57) and (662.87,1873.65) .. (674.38,1876.52)
 .. controls (677.98,1877.42) and (684.10,1875.43) .. (688.96,1876.68)
 .. controls (693.81,1877.93) and (700.65,1882.42) .. (700.65,1882.42)
),
((643.42,1900.60)
 .. controls (643.42,1900.60) and (606.67,1951.65) .. (646.50,2000.80)
),
((646.50,2000.80)
 .. controls (646.50,2000.80) and (654.43,2006.23) .. (656.95,2008.04)
 .. controls (659.47,2009.85) and (665.06,2013.65) .. (671.36,2013.66)
 .. controls (677.66,2013.66) and (676.04,2014.20) .. (680.18,2013.29)
 .. controls (684.32,2012.39) and (690.80,2012.73) .. (693.13,2008.05)
 .. controls (695.47,2003.36) and (701.23,1990.19) .. (701.23,1990.19)
),
((700.65,1882.42)
 -- (701.23,1990.19)
)));
current_src := "Romeo_entrance.th2 [310]";
string area_border[];
area_border[1] := "l6-10998-29848";
area_border[2] := "l5-11066-29995";
area_border[3] := "l7-11386-29954";
area_border[4] := "l6-10998-29848";
area_border[5] := "l289-10912-29738";
area_border[6] := "l213-10786-29310";
area_border[7] := "l290-11258-29489";
drawoptions();
a_sand(buildcycle(((701.40,2123.74)
 .. controls (697.08,2113.64) and (695.27,2104.45) .. (721.92,2077.82)
 .. controls (747.24,2052.52) and (761.70,2102.30) .. (761.70,2102.30)
),
((753.43,2142.49)
 .. controls (721.71,2140.09) and (705.73,2133.84) .. (701.40,2123.74)
),
((761.70,2102.30)
 .. controls (761.70,2102.30) and (785.21,2144.93) .. (753.43,2142.49)
),
((701.40,2123.74)
 .. controls (697.08,2113.64) and (695.27,2104.45) .. (721.92,2077.82)
 .. controls (747.24,2052.52) and (761.70,2102.30) .. (761.70,2102.30)
),
((646.50,2000.80)
 .. controls (648.48,2006.03) and (667.21,2035.23) .. (672.25,2046.91)
 .. controls (677.28,2058.59) and (687.89,2101.93) .. (689.88,2107.51)
 .. controls (691.86,2113.10) and (701.40,2123.74) .. (701.40,2123.74)
),
((646.50,2000.80)
 .. controls (646.50,2000.80) and (654.43,2006.23) .. (656.95,2008.04)
 .. controls (659.47,2009.85) and (665.06,2013.65) .. (671.36,2013.66)
 .. controls (677.66,2013.66) and (676.04,2014.20) .. (680.18,2013.29)
 .. controls (684.32,2012.39) and (690.80,2012.73) .. (693.13,2008.05)
 .. controls (695.47,2003.36) and (701.23,1990.19) .. (701.23,1990.19)
),
((701.23,1990.19)
 .. controls (701.23,1990.19) and (701.41,1997.05) .. (714.20,2009.85)
 .. controls (726.98,2022.66) and (742.82,2020.65) .. (746.41,2039.53)
 .. controls (750.00,2058.39) and (755.40,2079.07) .. (758.81,2081.76)
 .. controls (762.23,2084.46) and (759.72,2089.51) .. (761.70,2102.30)
)));
current_src := "Romeo_entrance.th2 [305]";
string area_border[];
area_border[1] := "l6-11026-27178";
area_border[2] := "l208-11076-27806";
drawoptions();
a_flowstone(buildcycle(((579.00,1358.63)
 .. controls (579.00,1358.63) and (577.83,1360.50) .. (576.33,1374.57)
 .. controls (575.42,1383.13) and (580.44,1391.03) .. (583.99,1397.93)
 .. controls (587.58,1404.89) and (604.52,1430.29) .. (610.78,1442.85)
 .. controls (616.97,1455.31) and (635.29,1485.00) .. (640.49,1489.33)
 .. controls (645.69,1493.68) and (660.77,1518.68) .. (663.45,1524.28)
 .. controls (666.13,1529.88) and (671.77,1555.70) .. (677.55,1571.37)
 .. controls (683.21,1586.68) and (695.94,1611.23) .. (699.51,1615.09)
 .. controls (703.08,1618.95) and (708.99,1635.90) .. (715.12,1649.14)
 .. controls (721.31,1662.47) and (722.27,1679.11) .. (723.36,1686.37)
 .. controls (724.45,1693.60) and (722.09,1710.46) .. (724.41,1718.83)
 .. controls (726.72,1727.19) and (719.28,1759.71) .. (718.38,1765.10)
 .. controls (717.48,1770.50) and (711.92,1788.93) .. (711.22,1803.59)
 .. controls (710.52,1818.24) and (705.51,1842.27) .. (703.89,1844.26)
 .. controls (702.27,1846.25) and (698.31,1860.65) .. (698.31,1863.89)
 .. controls (698.31,1867.12) and (697.95,1884.05) .. (696.16,1889.10)
 .. controls (694.36,1894.16) and (693.31,1909.35) .. (692.06,1918.39)
 .. controls (690.81,1927.42) and (693.33,1936.06) .. (694.22,1941.63)
 .. controls (695.12,1947.20) and (694.39,1968.58) .. (696.00,1976.32)
 .. controls (697.63,1984.06) and (697.45,1993.98) .. (699.25,2002.45)
 .. controls (701.05,2010.92) and (707.89,2013.46) .. (717.44,2017.61)
 .. controls (726.98,2021.76) and (737.95,2043.50) .. (740.47,2049.24)
 .. controls (742.99,2054.99) and (756.47,2083.57) .. (757.38,2088.97)
 .. controls (758.28,2094.37) and (775.21,2135.47) .. (778.10,2141.79)
 .. controls (780.98,2148.10) and (789.81,2159.46) .. (791.07,2164.68)
),
((716.22,1780.42)
 .. controls (716.22,1780.42) and (713.17,1782.24) .. (708.49,1780.98)
 .. controls (703.81,1779.73) and (700.75,1777.75) .. (699.49,1771.07)
 .. controls (698.22,1764.40) and (697.86,1759.35) .. (699.66,1755.22)
 .. controls (701.47,1751.10) and (704.17,1748.42) .. (707.06,1745.38)
 .. controls (709.94,1742.35) and (713.56,1738.61) .. (718.24,1738.61)
 .. controls (722.92,1738.61) and (725.79,1738.06) .. (725.79,1738.06)
)));
current_src := "Romeo_entrance.th2 [290]";
string area_border[];
area_border[1] := "l6-11026-27178";
area_border[2] := "l216-10266-25887";
area_border[3] := "l5-9716-25416";
area_border[4] := "l13-9659-26066";
area_border[5] := "l14-9757-26365";
area_border[6] := "l211-10474-26546";
drawoptions();
a_flowstone(buildcycle(((579.00,1358.63)
 .. controls (579.00,1358.63) and (577.83,1360.50) .. (576.33,1374.57)
 .. controls (575.42,1383.13) and (580.44,1391.03) .. (583.99,1397.93)
 .. controls (587.58,1404.89) and (604.52,1430.29) .. (610.78,1442.85)
 .. controls (616.97,1455.31) and (635.29,1485.00) .. (640.49,1489.33)
 .. controls (645.69,1493.68) and (660.77,1518.68) .. (663.45,1524.28)
 .. controls (666.13,1529.88) and (671.77,1555.70) .. (677.55,1571.37)
 .. controls (683.21,1586.68) and (695.94,1611.23) .. (699.51,1615.09)
 .. controls (703.08,1618.95) and (708.99,1635.90) .. (715.12,1649.14)
 .. controls (721.31,1662.47) and (722.27,1679.11) .. (723.36,1686.37)
 .. controls (724.45,1693.60) and (722.09,1710.46) .. (724.41,1718.83)
 .. controls (726.72,1727.19) and (719.28,1759.71) .. (718.38,1765.10)
 .. controls (717.48,1770.50) and (711.92,1788.93) .. (711.22,1803.59)
 .. controls (710.52,1818.24) and (705.51,1842.27) .. (703.89,1844.26)
 .. controls (702.27,1846.25) and (698.31,1860.65) .. (698.31,1863.89)
 .. controls (698.31,1867.12) and (697.95,1884.05) .. (696.16,1889.10)
 .. controls (694.36,1894.16) and (693.31,1909.35) .. (692.06,1918.39)
 .. controls (690.81,1927.42) and (693.33,1936.06) .. (694.22,1941.63)
 .. controls (695.12,1947.20) and (694.39,1968.58) .. (696.00,1976.32)
 .. controls (697.63,1984.06) and (697.45,1993.98) .. (699.25,2002.45)
 .. controls (701.05,2010.92) and (707.89,2013.46) .. (717.44,2017.61)
 .. controls (726.98,2021.76) and (737.95,2043.50) .. (740.47,2049.24)
 .. controls (742.99,2054.99) and (756.47,2083.57) .. (757.38,2088.97)
 .. controls (758.28,2094.37) and (775.21,2135.47) .. (778.10,2141.79)
 .. controls (780.98,2148.10) and (789.81,2159.46) .. (791.07,2164.68)
),
((552.87,1371.97)
 -- (570.54,1381.34)
 -- (581.50,1364.96)
),
((417.38,287.29)
 .. controls (417.38,287.29) and (411.62,294.66) .. (413.60,307.26)
 .. controls (415.58,319.85) and (423.31,337.47) .. (421.51,345.20)
 .. controls (419.71,352.94) and (417.18,361.21) .. (418.98,370.57)
 .. controls (420.78,379.93) and (425.10,398.65) .. (425.46,402.08)
 .. controls (425.82,405.50) and (424.38,424.95) .. (435.90,432.48)
 .. controls (447.41,440.02) and (462.52,458.88) .. (463.42,460.68)
 .. controls (464.32,462.48) and (487.00,488.55) .. (492.58,494.49)
 .. controls (498.16,500.43) and (519.05,527.83) .. (521.21,532.35)
 .. controls (523.38,536.86) and (547.15,579.92) .. (548.95,585.67)
 .. controls (550.75,591.43) and (555.23,608.85) .. (555.58,630.94)
 .. controls (555.93,653.06) and (554.31,673.06) .. (554.50,685.32)
 .. controls (554.68,697.58) and (554.86,716.13) .. (556.84,726.37)
 .. controls (558.81,736.61) and (570.14,775.61) .. (572.48,782.28)
 .. controls (574.83,788.96) and (583.13,812.82) .. (584.76,818.79)
 .. controls (586.38,824.74) and (586.75,833.58) .. (588.01,841.14)
 .. controls (589.26,848.68) and (594.29,855.84) .. (603.63,864.77)
 .. controls (612.97,873.69) and (632.55,900.36) .. (635.25,905.92)
 .. controls (637.94,911.47) and (656.80,953.43) .. (658.60,963.86)
 .. controls (660.40,974.31) and (666.39,1018.23) .. (664.96,1032.17)
 .. controls (663.54,1046.06) and (653.41,1078.08) .. (632.08,1095.26)
 .. controls (610.77,1112.41) and (555.36,1152.27) .. (550.88,1154.67)
 .. controls (546.40,1157.07) and (525.37,1173.54) .. (496.88,1160.31)
 .. controls (468.34,1147.07) and (447.30,1136.79) .. (444.06,1134.48)
 .. controls (440.83,1132.16) and (412.99,1114.81) .. (411.48,1155.18)
 .. controls (409.98,1195.67) and (408.01,1202.53) .. (409.98,1208.45)
 .. controls (411.96,1214.39) and (410.50,1224.63) .. (425.65,1234.95)
 .. controls (440.66,1245.17) and (456.55,1255.39) .. (457.61,1260.52)
 .. controls (458.66,1265.63) and (468.30,1310.70) .. (469.96,1318.67)
 .. controls (471.63,1326.65) and (473.57,1359.46) .. (474.27,1369.36)
 .. controls (474.99,1379.46) and (477.90,1416.44) .. (480.12,1421.00)
 .. controls (482.34,1425.53) and (483.74,1447.15) .. (502.35,1437.73)
 .. controls (522.23,1427.66) and (527.56,1425.82) .. (530.00,1423.56)
 .. controls (532.42,1421.31) and (541.86,1410.44) .. (542.93,1406.76)
 .. controls (543.99,1403.11) and (545.25,1401.85) .. (549.15,1399.20)
 .. controls (553.05,1396.56) and (558.10,1396.38) .. (559.76,1392.86)
 .. controls (561.40,1389.39) and (563.13,1387.56) .. (561.41,1381.75)
 .. controls (559.21,1374.31) and (559.26,1373.28) .. (555.48,1368.71)
),
((479.35,1399.94)
 .. controls (479.35,1399.94) and (474.11,1404.81) .. (471.04,1409.20)
 .. controls (467.98,1413.55) and (465.27,1416.64) .. (461.82,1419.73)
 .. controls (458.39,1422.81) and (454.68,1430.14) .. (455.79,1431.66)
 .. controls (456.89,1433.17) and (457.68,1435.11) .. (454.91,1439.52)
 .. controls (452.18,1443.88) and (447.56,1452.67) .. (454.75,1454.23)
 .. controls (461.82,1455.77) and (468.55,1462.01) .. (474.79,1459.06)
 .. controls (481.09,1456.08) and (482.41,1451.64) .. (482.41,1451.64)
),
((551.17,1481.73)
 .. controls (546.65,1483.80) and (538.73,1489.59) .. (533.45,1492.89)
 .. controls (528.12,1496.22) and (513.54,1500.75) .. (505.77,1501.52)
 .. controls (498.53,1502.24) and (487.77,1497.05) .. (482.41,1493.34)
 .. controls (477.12,1489.67) and (477.13,1485.46) .. (476.45,1480.93)
 .. controls (475.78,1476.41) and (471.97,1469.37) .. (471.64,1466.58)
 .. controls (471.30,1463.78) and (470.26,1458.14) .. (470.26,1458.14)
),
((541.38,1487.53)
 .. controls (541.38,1487.53) and (540.99,1490.00) .. (544.34,1496.21)
 .. controls (547.69,1502.42) and (552.51,1511.95) .. (556.21,1514.47)
 .. controls (559.89,1516.97) and (565.64,1520.35) .. (572.75,1520.45)
 .. controls (579.72,1520.55) and (595.13,1520.71) .. (599.99,1515.64)
 .. controls (604.84,1510.57) and (612.23,1503.61) .. (615.20,1500.51)
 .. controls (618.17,1497.42) and (623.57,1489.22) .. (625.82,1486.51)
 .. controls (628.07,1483.80) and (631.51,1474.30) .. (631.51,1474.30)
)));
current_src := "Romeo_entrance.th2 [232]";
string area_border[];
area_border[1] := "l586-9470-25910";
drawoptions();
a_clay(buildcycle(((336.76,1251.64)
 .. controls (336.76,1251.64) and (341.53,1226.87) .. (340.84,1222.91)
 .. controls (333.49,1180.80) and (425.60,1218.89) .. (425.60,1218.89)
 -- (466.73,1247.46)
 .. controls (466.73,1247.46) and (505.39,1265.24) .. (480.82,1347.21)
 .. controls (453.74,1437.56) and (390.88,1378.16) .. (390.88,1378.16)
 -- cycle
)));
current_src := "Romeo_entrance.th2 [211]";
string area_border[];
area_border[1] := "l169-9400-20832";
area_border[2] := "l593-9608-22152";
drawoptions();
a_blocks(buildcycle(((322.49,457.09)
 .. controls (324.29,455.30) and (345.00,454.08) .. (353.64,454.64)
 .. controls (362.28,455.19) and (390.90,465.81) .. (397.38,470.29)
 .. controls (403.86,474.78) and (418.07,489.85) .. (422.93,494.88)
 .. controls (427.78,499.91) and (456.22,528.51) .. (459.46,532.12)
 .. controls (462.70,535.72) and (488.10,569.46) .. (491.53,578.48)
 .. controls (494.95,587.48) and (498.37,596.84) .. (498.01,601.33)
 .. controls (497.64,605.82) and (506.63,629.18) .. (508.24,634.74)
 .. controls (509.86,640.32) and (513.46,664.44) .. (515.08,668.59)
 .. controls (516.71,672.74) and (517.80,700.18) .. (516.37,704.33)
 .. controls (514.93,708.48) and (508.81,725.93) .. (507.54,729.88)
 .. controls (506.28,733.83) and (500.14,749.96) .. (498.33,753.36)
 .. controls (496.53,756.76) and (491.83,768.58) .. (490.03,769.83)
 .. controls (488.23,771.08) and (485.52,783.45) .. (485.52,783.45)
),
((485.52,783.45)
 .. controls (485.52,783.45) and (303.21,479.71) .. (322.49,457.09)
)));
current_src := "Romeo_entrance.th2 [200]";
string area_border[];
area_border[1] := "l181-8986-19593";
area_border[2] := "l595-8816-19340";
drawoptions();
a_sand(buildcycle(((396.50,244.80)
 .. controls (396.50,244.80) and (390.92,245.70) .. (388.40,245.70)
 .. controls (385.88,245.69) and (382.64,244.61) .. (377.78,245.87)
 .. controls (372.92,247.13) and (372.02,249.47) .. (369.86,252.71)
 .. controls (367.70,255.95) and (366.44,256.85) .. (363.74,261.89)
 .. controls (361.04,266.94) and (354.38,266.57) .. (348.62,264.59)
 .. controls (342.86,262.60) and (337.64,260.79) .. (331.88,261.69)
 .. controls (326.12,262.58) and (326.48,264.02) .. (322.16,266.36)
 .. controls (317.84,268.70) and (318.02,272.12) .. (316.58,275.90)
 .. controls (315.13,279.67) and (309.37,284.71) .. (307.57,285.25)
),
((307.57,285.25)
 .. controls (307.57,285.25) and (284.53,55.02) .. (396.50,244.80)
)));
current_src := "Romeo_entrance.th2 [106]";
string area_border[];
area_border[1] := "l5-11066-29995";
area_border[2] := "l6-10998-29848";
area_border[3] := "l7-11386-29954";
drawoptions();
a_pebbles(buildcycle(((753.43,2142.49)
 .. controls (721.71,2140.09) and (705.73,2133.84) .. (701.40,2123.74)
),
((701.40,2123.74)
 .. controls (697.08,2113.64) and (695.27,2104.45) .. (721.92,2077.82)
 .. controls (747.24,2052.52) and (761.70,2102.30) .. (761.70,2102.30)
),
((761.70,2102.30)
 .. controls (761.70,2102.30) and (785.21,2144.93) .. (753.43,2142.49)
)));
current_src := "Romeo_entrance.th2 [15]";
string area_border[];
area_border[1] := "l177-10200-24128";
area_border[2] := "l173-10224-23120";
area_border[3] := "l591-10140-23538";
drawoptions();
a_blocks(buildcycle(((555.45,1011.03)
 .. controls (555.45,1011.03) and (554.69,1046.16) .. (551.80,1061.94)
 .. controls (548.91,1077.76) and (561.15,1079.93) .. (563.31,1092.18)
 .. controls (565.48,1104.45) and (576.26,1110.85) .. (576.26,1110.85)
),
((519.54,864.09)
 .. controls (521.88,864.82) and (527.64,868.62) .. (531.61,870.43)
 .. controls (535.57,872.25) and (548.00,882.00) .. (550.34,884.34)
 .. controls (552.68,886.69) and (562.23,897.71) .. (566.38,903.14)
 .. controls (570.52,908.56) and (577.01,920.29) .. (579.53,924.97)
 .. controls (582.05,929.65) and (589.94,945.40) .. (591.74,948.25)
 .. controls (593.53,951.10) and (596.01,972.56) .. (596.54,977.57)
 .. controls (597.08,982.59) and (596.17,997.14) .. (596.17,1005.43)
 .. controls (596.18,1013.73) and (593.65,1015.34) .. (592.75,1017.86)
 .. controls (591.85,1020.38) and (596.73,1022.22) .. (597.63,1023.14)
 .. controls (598.53,1024.05) and (612.62,1029.26) .. (613.88,1029.63)
 .. controls (615.15,1030.00) and (619.48,1030.58) .. (621.64,1032.05)
 .. controls (623.81,1033.51) and (625.62,1036.42) .. (626.16,1037.32)
 .. controls (626.70,1038.23) and (624.54,1042.19) .. (624.00,1043.99)
 .. controls (623.46,1045.79) and (620.39,1055.09) .. (620.38,1058.30)
 .. controls (620.37,1061.51) and (617.08,1072.65) .. (613.99,1077.23)
 .. controls (610.90,1081.80) and (605.43,1083.65) .. (593.72,1094.12)
 .. controls (581.96,1104.63) and (564.61,1115.33) .. (558.34,1117.79)
 .. controls (552.07,1120.25) and (542.94,1123.83) .. (538.81,1126.41)
 .. controls (534.69,1128.99) and (532.89,1129.53) .. (530.37,1130.25)
 .. controls (527.85,1130.96) and (528.37,1126.94) .. (526.92,1124.91)
 .. controls (525.47,1122.89) and (518.21,1112.58) .. (512.03,1100.34)
 .. controls (505.90,1088.19) and (495.08,1087.26) .. (491.12,1085.82)
 .. controls (487.16,1084.38) and (471.16,1080.30) .. (464.51,1078.03)
 .. controls (457.88,1075.75) and (444.07,1070.91) .. (439.22,1070.60)
 .. controls (434.38,1070.30) and (418.05,1066.52) .. (415.89,1065.82)
 .. controls (413.74,1065.11) and (402.76,1063.69) .. (400.06,1063.32)
 .. controls (397.35,1062.95) and (373.00,1060.59) .. (370.83,1060.21)
 .. controls (368.67,1059.83) and (362.88,1066.39) .. (362.88,1066.39)
),
((555.45,1011.03)
 -- (519.54,864.09)
)));
ATTR__id := "l159-9404-24340";
ATTR__height := -1;
drawoptions();
l_border_invisible(((434.34,1142.16)
 .. controls (434.34,1142.16) and (409.23,1110.91) .. (402.06,1105.22)
 .. controls (394.87,1099.54) and (365.42,1058.72) .. (366.88,1038.62)
));
ATTR__id := "l177-10200-24128";
ATTR__height := -1;
drawoptions();
l_border_invisible(((555.45,1011.03)
 .. controls (555.45,1011.03) and (554.69,1046.16) .. (551.80,1061.94)
 .. controls (548.91,1077.76) and (561.15,1079.93) .. (563.31,1092.18)
 .. controls (565.48,1104.45) and (576.26,1110.85) .. (576.26,1110.85)
));
ATTR__id := "l588-10096-23664";
ATTR__height := -1;
drawoptions();
l_border_visible(((555.45,1011.03)
 -- (486.36,944.87)
 -- (362.88,1066.39)
));
ATTR__id := "l179-10084-22912";
ATTR__height := -1;
drawoptions();
l_border_invisible(((518.09,875.24)
 -- (535.39,860.20)
));
ATTR__id := "l181-8986-19593";
ATTR__height := -1;
drawoptions();
l_border_invisible(((396.50,244.80)
 .. controls (396.50,244.80) and (390.92,245.70) .. (388.40,245.70)
 .. controls (385.88,245.69) and (382.64,244.61) .. (377.78,245.87)
 .. controls (372.92,247.13) and (372.02,249.47) .. (369.86,252.71)
 .. controls (367.70,255.95) and (366.44,256.85) .. (363.74,261.89)
 .. controls (361.04,266.94) and (354.38,266.57) .. (348.62,264.59)
 .. controls (342.86,262.60) and (337.64,260.79) .. (331.88,261.69)
 .. controls (326.12,262.58) and (326.48,264.02) .. (322.16,266.36)
 .. controls (317.84,268.70) and (318.02,272.12) .. (316.58,275.90)
 .. controls (315.13,279.67) and (309.37,284.71) .. (307.57,285.25)
));
ATTR__id := "l183-9896-18512";
ATTR__height := -1;
drawoptions();
l_border_invisible(((391.46,-161.81)
 .. controls (394.52,-159.29) and (405.50,-152.45) .. (409.64,-145.43)
 .. controls (413.78,-138.41) and (415.94,-124.73) .. (418.82,-116.26)
 .. controls (421.70,-107.80) and (425.12,-107.27) .. (431.78,-103.85)
 .. controls (438.44,-100.43) and (454.64,-86.40) .. (458.96,-82.80)
 .. controls (463.28,-79.21) and (482.00,-56.35) .. (485.96,-50.23)
 .. controls (489.92,-44.11) and (503.24,-20.17) .. (505.58,-8.47)
 .. controls (507.92,3.23) and (506.30,49.13) .. (505.22,53.45)
 .. controls (504.14,57.77) and (500.90,71.63) .. (499.28,83.87)
 .. controls (497.66,96.12) and (490.28,121.51) .. (487.22,127.45)
 .. controls (484.16,133.40) and (474.80,141.32) .. (467.24,143.66)
 .. controls (459.68,146.00) and (446.90,131.77) .. (443.84,128.53)
 .. controls (440.78,125.28) and (431.60,111.60) .. (429.62,106.92)
 .. controls (427.64,102.24) and (415.04,93.41) .. (413.60,92.15)
));
ATTR__id := "l607-9326-19350";
ATTR__height := -1;
drawoptions();
l_border_invisible(((396.50,244.80)
 -- (413.60,92.15)
));
ATTR__id := "l608-9224-17162";
ATTR__height := -1;
drawoptions();
l_border_invisible(((391.46,-161.81)
 .. controls (391.46,-161.81) and (195.27,-399.24) .. (221.55,-435.95)
));
ATTR__id := "l609-8620-15342";
ATTR__height := -1;
drawoptions();
l_border_invisible(((248.19,-551.15)
 -- (306.14,-433.25)
));
ATTR__id := "l610-10188-18254";
ATTR__height := -1;
drawoptions();
l_border_invisible(((543.37,-63.40)
 -- (562.82,77.72)
 -- (614.28,240.39)
 -- (447.61,329.72)
));
ATTR__id := "l189-8350-14756";
ATTR__height := -1;
drawoptions();
l_border_invisible(((183.03,-552.22)
 .. controls (183.03,-552.22) and (190.23,-585.70) .. (189.14,-595.78)
 .. controls (188.06,-605.86) and (184.10,-627.82) .. (184.46,-634.30)
 .. controls (184.82,-640.78) and (179.42,-647.62) .. (189.86,-644.02)
 .. controls (200.30,-640.42) and (211.82,-626.38) .. (214.71,-621.34)
 .. controls (217.59,-616.30) and (225.51,-605.86) .. (230.19,-598.66)
 .. controls (234.87,-591.46) and (245.67,-584.26) .. (245.67,-584.26)
));
ATTR__id := "l191-7944-14488";
ATTR__height := -1;
drawoptions();
l_border_invisible(((92.67,-682.17)
 .. controls (98.43,-678.21) and (125.07,-668.14) .. (129.39,-666.70)
 .. controls (133.71,-665.26) and (163.58,-652.30) .. (168.26,-650.14)
 .. controls (172.94,-647.98) and (186.62,-643.30) .. (186.62,-643.30)
));
ATTR__id := "l192-7526-13736";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-94.53,-1004.00)
 .. controls (-92.37,-1004.01) and (-54.93,-989.97) .. (-43.77,-979.53)
 .. controls (-32.61,-969.08) and (-13.16,-954.68) .. (-3.08,-948.20)
 .. controls (6.99,-941.72) and (15.63,-939.92) .. (21.39,-937.41)
 .. controls (27.15,-934.89) and (36.51,-912.92) .. (36.87,-906.08)
 .. controls (37.23,-899.24) and (41.20,-880.52) .. (44.80,-868.28)
 .. controls (48.39,-856.04) and (52.35,-844.53) .. (55.23,-835.89)
 .. controls (58.11,-827.25) and (65.67,-809.25) .. (69.63,-802.05)
 .. controls (73.59,-794.85) and (87.27,-765.33) .. (89.07,-755.25)
 .. controls (90.87,-745.17) and (86.19,-721.05) .. (84.75,-714.93)
 .. controls (83.32,-708.81) and (79.00,-694.05) .. (77.92,-691.89)
));
ATTR__id := "l194-6756-12360";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-13.52,-1013.00)
 .. controls (-15.32,-1013.72) and (-31.88,-1015.16) .. (-35.48,-1019.84)
 .. controls (-39.09,-1024.52) and (-43.77,-1027.76) .. (-52.41,-1032.80)
 .. controls (-61.05,-1037.84) and (-65.73,-1039.28) .. (-69.69,-1045.76)
 .. controls (-73.65,-1052.24) and (-74.36,-1059.08) .. (-74.00,-1065.56)
 .. controls (-73.64,-1072.04) and (-77.60,-1076.72) .. (-77.60,-1082.12)
 .. controls (-77.61,-1087.52) and (-76.89,-1089.68) .. (-75.45,-1092.20)
 .. controls (-74.01,-1094.72) and (-64.65,-1103.72) .. (-64.65,-1103.72)
));
ATTR__id := "l195-6512-12060";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-124.05,-1061.24)
 .. controls (-124.05,-1065.20) and (-124.42,-1078.89) .. (-122.98,-1081.41)
 .. controls (-121.54,-1083.93) and (-123.34,-1091.13) .. (-117.22,-1092.93)
 .. controls (-111.10,-1094.73) and (-97.05,-1095.80) .. (-92.37,-1094.36)
 .. controls (-87.69,-1092.92) and (-83.01,-1090.04) .. (-80.85,-1090.04)
 .. controls (-78.69,-1090.04) and (-72.93,-1088.96) .. (-72.93,-1088.96)
));
ATTR__id := "l196-6316-11828";
ATTR__height := -1;
drawoptions();
l_flowstone(((-205.37,-1267.09)
 .. controls (-205.37,-1267.09) and (-196.38,-1267.10) .. (-189.90,-1266.39)
 .. controls (-183.43,-1265.67) and (-171.55,-1264.24) .. (-167.60,-1263.17)
 .. controls (-163.64,-1262.09) and (-146.01,-1252.75) .. (-139.18,-1248.08)
 .. controls (-132.34,-1243.41) and (-124.07,-1232.25) .. (-123.35,-1223.97)
 .. controls (-122.62,-1215.68) and (-121.90,-1207.76) .. (-120.46,-1196.95)
 .. controls (-119.01,-1186.15) and (-119.37,-1170.67) .. (-121.17,-1161.67)
 .. controls (-122.97,-1152.67) and (-130.17,-1143.67) .. (-134.85,-1141.15)
 .. controls (-139.53,-1138.63) and (-154.64,-1127.47) .. (-154.64,-1127.47)
));
ATTR__id := "l197-6472-11896";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-134.13,-1147.99)
 .. controls (-128.73,-1143.67) and (-128.73,-1136.11) .. (-125.49,-1132.52)
 .. controls (-122.25,-1128.92) and (-109.65,-1122.44) .. (-105.33,-1119.20)
 .. controls (-101.01,-1115.96) and (-101.73,-1112.72) .. (-94.89,-1112.00)
 .. controls (-88.05,-1111.28) and (-68.61,-1115.96) .. (-66.09,-1118.48)
));
ATTR__id := "l200-6296-10916";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-147.81,-1246.99)
 .. controls (-147.81,-1246.99) and (-144.93,-1261.75) .. (-145.64,-1275.42)
 .. controls (-146.36,-1289.09) and (-148.15,-1313.56) .. (-145.27,-1321.12)
 .. controls (-142.39,-1328.69) and (-137.72,-1326.89) .. (-141.67,-1335.17)
 .. controls (-145.63,-1343.44) and (-166.16,-1364.69) .. (-172.66,-1378.39)
 .. controls (-179.15,-1392.08) and (-182.76,-1408.65) .. (-182.75,-1417.64)
 .. controls (-182.74,-1426.63) and (-198.55,-1469.79) .. (-204.32,-1477.35)
 .. controls (-210.08,-1484.91) and (-213.69,-1500.77) .. (-216.57,-1512.66)
 .. controls (-219.45,-1524.54) and (-219.81,-1542.16) .. (-225.56,-1545.39)
 .. controls (-231.31,-1548.62) and (-235.26,-1549.69) .. (-244.26,-1549.32)
 .. controls (-253.25,-1548.96) and (-261.18,-1551.48) .. (-272.35,-1557.26)
 .. controls (-283.53,-1563.04) and (-298.66,-1564.52) .. (-305.15,-1568.49)
 .. controls (-311.64,-1572.45) and (-313.08,-1572.09) .. (-315.60,-1582.53)
 .. controls (-318.11,-1592.95) and (-320.62,-1597.98) .. (-320.24,-1607.31)
 .. controls (-319.86,-1616.64) and (-328.48,-1618.78) .. (-319.12,-1624.17)
 .. controls (-309.75,-1629.55) and (-305.06,-1632.78) .. (-298.94,-1630.98)
 .. controls (-292.82,-1629.19) and (-278.77,-1632.76) .. (-278.77,-1632.76)
));
ATTR__id := "l201-4832-9212";
ATTR__height := -1;
drawoptions();
l_flowstone(((-488.15,-1599.79)
 .. controls (-488.15,-1599.79) and (-474.87,-1612.09) .. (-465.88,-1615.35)
 .. controls (-456.90,-1618.62) and (-432.77,-1615.73) .. (-422.33,-1612.49)
 .. controls (-411.90,-1609.25) and (-368.41,-1587.41) .. (-359.79,-1582.05)
 .. controls (-351.18,-1576.68) and (-329.98,-1569.55) .. (-320.62,-1560.55)
 .. controls (-310.69,-1551.00) and (-306.56,-1541.43) .. (-300.77,-1529.16)
 .. controls (-298.85,-1525.07) and (-298.25,-1517.03) .. (-303.99,-1511.84)
 .. controls (-314.78,-1502.10) and (-321.25,-1502.82) .. (-328.44,-1498.84)
 .. controls (-335.63,-1494.87) and (-352.89,-1483.30) .. (-352.89,-1483.30)
));
ATTR__id := "l624-5116-9242";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-499.73,-1638.05)
 -- (-484.32,-1648.59)
 -- (-456.95,-1640.66)
 -- (-450.18,-1664.16)
 -- (-401.48,-1711.52)
 -- (-375.53,-1691.32)
 -- (-327.33,-1649.27)
 -- (-333.52,-1616.61)
 -- (-358.70,-1599.67)
 -- (-377.02,-1598.17)
 -- (-407.94,-1613.22)
 -- (-450.06,-1621.14)
 -- (-480.27,-1614.25)
 -- cycle
));
ATTR__id := "l627-5152-9338";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-490.39,-1636.28)
 .. controls (-490.39,-1636.28) and (-492.50,-1618.58) .. (-470.21,-1621.49)
 .. controls (-447.91,-1624.41) and (-437.12,-1627.63) .. (-421.26,-1620.42)
 .. controls (-405.42,-1613.22) and (-378.10,-1599.24) .. (-366.97,-1593.53)
 .. controls (-355.84,-1587.81) and (-348.66,-1577.07) .. (-330.70,-1575.67)
 .. controls (-312.72,-1574.27) and (-318.84,-1578.93) .. (-324.57,-1596.53)
 .. controls (-330.29,-1614.11) and (-328.12,-1620.93) .. (-324.14,-1628.47)
 .. controls (-320.17,-1636.00) and (-312.97,-1634.93) .. (-310.44,-1641.75)
 .. controls (-307.90,-1648.56) and (-310.36,-1681.58) .. (-318.99,-1689.13)
 .. controls (-327.62,-1696.67) and (-387.76,-1733.42) .. (-387.76,-1733.42)
 .. controls (-387.76,-1733.42) and (-428.57,-1703.36) .. (-435.06,-1688.28)
 .. controls (-441.56,-1673.17) and (-450.51,-1654.04) .. (-457.69,-1647.17)
 .. controls (-464.87,-1640.30) and (-478.56,-1647.52) .. (-485.02,-1642.44)
 .. controls (-491.47,-1637.36) and (-490.39,-1636.28) .. cycle
));
ATTR__id := "l630-6180-10998";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-273.40,-1506.45)
 .. controls (-273.40,-1506.45) and (-288.08,-1520.19) .. (-288.52,-1520.86)
 .. controls (-301.15,-1539.99) and (-312.69,-1546.49) .. (-300.10,-1555.50)
 .. controls (-287.50,-1564.50) and (-247.50,-1543.92) .. (-243.18,-1542.49)
 .. controls (-238.86,-1541.05) and (-222.32,-1521.29) .. (-215.47,-1485.99)
 .. controls (-208.63,-1450.71) and (-179.88,-1403.97) .. (-178.42,-1385.96)
 .. controls (-176.97,-1367.94) and (-149.95,-1337.32) .. (-156.79,-1319.32)
 .. controls (-163.63,-1301.32) and (-158.59,-1283.69) .. (-178.03,-1281.51)
 .. controls (-197.45,-1279.34) and (-191.70,-1280.06) .. (-202.49,-1301.29)
 .. controls (-213.29,-1322.52) and (-228.41,-1335.47) .. (-233.09,-1343.75)
 .. controls (-237.77,-1352.03) and (-274.46,-1445.59) .. (-274.46,-1445.59)
 .. controls (-274.46,-1445.59) and (-268.35,-1447.04) .. (-266.19,-1480.53)
 .. controls (-265.82,-1486.32) and (-269.44,-1498.89) .. (-269.44,-1498.89)
 -- cycle
));
ATTR__id := "l184-9852-17572";
ATTR__height := -1;
drawoptions();
l_border_invisible(((543.37,-63.40)
 .. controls (541.21,-65.73) and (521.05,-81.21) .. (514.75,-86.60)
 .. controls (508.45,-92.00) and (488.84,-101.53) .. (485.24,-108.37)
 .. controls (481.64,-115.21) and (475.34,-123.85) .. (473.00,-130.32)
 .. controls (470.66,-136.80) and (472.27,-147.78) .. (471.19,-153.00)
 .. controls (470.11,-158.22) and (470.29,-165.60) .. (466.51,-176.39)
 .. controls (462.73,-187.19) and (454.81,-200.33) .. (453.01,-207.70)
 .. controls (451.21,-215.08) and (442.93,-222.64) .. (440.05,-229.84)
 .. controls (437.17,-237.04) and (427.81,-250.00) .. (424.75,-253.61)
 .. controls (421.69,-257.21) and (395.96,-283.50) .. (392.36,-290.34)
 .. controls (388.76,-297.18) and (367.88,-324.90) .. (363.74,-330.12)
 .. controls (359.60,-335.34) and (351.50,-351.17) .. (348.62,-358.01)
 .. controls (345.74,-364.85) and (344.48,-367.37) .. (338.90,-372.23)
 .. controls (333.32,-377.09) and (327.38,-383.93) .. (322.52,-390.05)
 .. controls (317.66,-396.17) and (310.28,-407.87) .. (309.38,-412.73)
 .. controls (308.48,-417.59) and (306.68,-428.57) .. (306.14,-433.25)
));
ATTR__id := "l187-8364-15472";
ATTR__height := -1;
drawoptions();
l_border_invisible(((221.55,-435.95)
 .. controls (222.63,-439.91) and (226.59,-451.07) .. (226.59,-462.23)
 .. controls (226.59,-473.39) and (222.63,-484.19) .. (224.79,-492.47)
 .. controls (226.95,-500.75) and (224.43,-510.11) .. (226.95,-518.75)
 .. controls (229.47,-527.39) and (227.67,-536.03) .. (231.63,-539.99)
 .. controls (235.59,-543.95) and (244.95,-547.91) .. (248.19,-551.15)
));
ATTR__id := "l169-9400-20832";
ATTR__height := -1;
drawoptions();
l_border_invisible(((322.49,457.09)
 .. controls (324.29,455.30) and (345.00,454.08) .. (353.64,454.64)
 .. controls (362.28,455.19) and (390.90,465.81) .. (397.38,470.29)
 .. controls (403.86,474.78) and (418.07,489.85) .. (422.93,494.88)
 .. controls (427.78,499.91) and (456.22,528.51) .. (459.46,532.12)
 .. controls (462.70,535.72) and (488.10,569.46) .. (491.53,578.48)
 .. controls (494.95,587.48) and (498.37,596.84) .. (498.01,601.33)
 .. controls (497.64,605.82) and (506.63,629.18) .. (508.24,634.74)
 .. controls (509.86,640.32) and (513.46,664.44) .. (515.08,668.59)
 .. controls (516.71,672.74) and (517.80,700.18) .. (516.37,704.33)
 .. controls (514.93,708.48) and (508.81,725.93) .. (507.54,729.88)
 .. controls (506.28,733.83) and (500.14,749.96) .. (498.33,753.36)
 .. controls (496.53,756.76) and (491.83,768.58) .. (490.03,769.83)
 .. controls (488.23,771.08) and (485.52,783.45) .. (485.52,783.45)
));
ATTR__id := "l173-10224-23120";
ATTR__height := -1;
drawoptions();
l_border_invisible(((519.54,864.09)
 .. controls (521.88,864.82) and (527.64,868.62) .. (531.61,870.43)
 .. controls (535.57,872.25) and (548.00,882.00) .. (550.34,884.34)
 .. controls (552.68,886.69) and (562.23,897.71) .. (566.38,903.14)
 .. controls (570.52,908.56) and (577.01,920.29) .. (579.53,924.97)
 .. controls (582.05,929.65) and (589.94,945.40) .. (591.74,948.25)
 .. controls (593.53,951.10) and (596.01,972.56) .. (596.54,977.57)
 .. controls (597.08,982.59) and (596.17,997.14) .. (596.17,1005.43)
 .. controls (596.18,1013.73) and (593.65,1015.34) .. (592.75,1017.86)
 .. controls (591.85,1020.38) and (596.73,1022.22) .. (597.63,1023.14)
 .. controls (598.53,1024.05) and (612.62,1029.26) .. (613.88,1029.63)
 .. controls (615.15,1030.00) and (619.48,1030.58) .. (621.64,1032.05)
 .. controls (623.81,1033.51) and (625.62,1036.42) .. (626.16,1037.32)
 .. controls (626.70,1038.23) and (624.54,1042.19) .. (624.00,1043.99)
 .. controls (623.46,1045.79) and (620.39,1055.09) .. (620.38,1058.30)
 .. controls (620.37,1061.51) and (617.08,1072.65) .. (613.99,1077.23)
 .. controls (610.90,1081.80) and (605.43,1083.65) .. (593.72,1094.12)
 .. controls (581.96,1104.63) and (564.61,1115.33) .. (558.34,1117.79)
 .. controls (552.07,1120.25) and (542.94,1123.83) .. (538.81,1126.41)
 .. controls (534.69,1128.99) and (532.89,1129.53) .. (530.37,1130.25)
 .. controls (527.85,1130.96) and (528.37,1126.94) .. (526.92,1124.91)
 .. controls (525.47,1122.89) and (518.21,1112.58) .. (512.03,1100.34)
 .. controls (505.90,1088.19) and (495.08,1087.26) .. (491.12,1085.82)
 .. controls (487.16,1084.38) and (471.16,1080.30) .. (464.51,1078.03)
 .. controls (457.88,1075.75) and (444.07,1070.91) .. (439.22,1070.60)
 .. controls (434.38,1070.30) and (418.05,1066.52) .. (415.89,1065.82)
 .. controls (413.74,1065.11) and (402.76,1063.69) .. (400.06,1063.32)
 .. controls (397.35,1062.95) and (373.00,1060.59) .. (370.83,1060.21)
 .. controls (368.67,1059.83) and (362.88,1066.39) .. (362.88,1066.39)
));
ATTR__id := "l163-9132-20000";
ATTR__height := -1;
drawoptions();
l_border_invisible(((274.08,341.88)
 -- (447.61,329.72)
));
ATTR__id := "l604-9758-20332";
ATTR__height := -1;
drawoptions();
l_border_invisible(((447.61,329.72)
 -- (533.27,526.20)
 -- (593.36,660.72)
 -- (594.44,791.47)
 -- (588.01,841.14)
));
ATTR__id := "l606-8760-19828";
ATTR__height := -1;
drawoptions();
l_border_invisible(((274.08,341.88)
 -- (307.57,285.25)
));
ATTR__id := "l239-2820-7090";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-795.91,-1975.78)
 .. controls (-795.91,-1975.78) and (-791.72,-1978.41) .. (-785.72,-1978.38)
 .. controls (-779.75,-1978.35) and (-766.72,-1981.62) .. (-759.57,-1980.66)
 .. controls (-752.43,-1979.70) and (-743.24,-1981.46) .. (-736.93,-1984.44)
 .. controls (-730.61,-1987.42) and (-721.44,-1992.75) .. (-714.48,-1990.69)
 .. controls (-707.30,-1988.56) and (-697.99,-1985.73) .. (-689.27,-1996.64)
 .. controls (-680.62,-2007.46) and (-679.54,-2012.04) .. (-673.97,-2016.80)
 .. controls (-668.40,-2021.57) and (-671.86,-2025.97) .. (-643.86,-2030.83)
 .. controls (-615.91,-2035.69) and (-606.96,-2039.41) .. (-605.53,-2038.71)
));
ATTR__id := "l240-2678-6802";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-800.50,-1982.20)
 .. controls (-800.50,-1982.20) and (-796.84,-2006.23) .. (-794.25,-2013.11)
 .. controls (-791.71,-2019.87) and (-784.78,-2030.96) .. (-780.00,-2035.51)
 .. controls (-775.12,-2040.15) and (-764.00,-2052.21) .. (-762.08,-2053.73)
));
ATTR__id := "l241-3598-7320";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-670.58,-1904.14)
 .. controls (-670.58,-1904.14) and (-672.10,-1923.72) .. (-671.83,-1932.13)
 .. controls (-671.57,-1940.56) and (-671.66,-1944.99) .. (-667.73,-1950.81)
 .. controls (-663.81,-1956.62) and (-659.81,-1960.53) .. (-655.44,-1962.27)
 .. controls (-651.08,-1964.00) and (-645.29,-1963.58) .. (-642.77,-1959.26)
 .. controls (-640.25,-1954.96) and (-639.55,-1948.85) .. (-634.19,-1947.12)
 .. controls (-628.84,-1945.40) and (-624.94,-1942.62) .. (-618.54,-1941.67)
 .. controls (-612.15,-1940.74) and (-605.04,-1941.24) .. (-601.90,-1934.55)
 .. controls (-598.74,-1927.84) and (-593.06,-1923.65) .. (-589.85,-1917.23)
 .. controls (-586.62,-1910.76) and (-585.87,-1904.23) .. (-585.87,-1904.23)
));
ATTR__id := "l244-3164-7184";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-758.87,-1952.92)
 .. controls (-758.87,-1952.92) and (-739.71,-1962.63) .. (-727.26,-1966.44)
 .. controls (-714.73,-1970.28) and (-690.35,-1977.10) .. (-680.82,-1979.31)
 .. controls (-671.25,-1981.54) and (-662.34,-1988.25) .. (-658.73,-1979.26)
 .. controls (-655.10,-1970.20) and (-652.52,-1956.80) .. (-652.52,-1956.80)
));
ATTR__id := "l245-3602-6960";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-678.12,-2020.85)
 .. controls (-678.12,-2020.85) and (-653.03,-2018.51) .. (-645.15,-2016.41)
 .. controls (-637.27,-2014.32) and (-611.21,-2001.36) .. (-611.21,-2001.36)
));
ATTR__id := "l246-4178-7582";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-540.12,-1858.83)
 .. controls (-540.12,-1858.83) and (-527.99,-1879.13) .. (-527.97,-1889.92)
 .. controls (-527.95,-1900.66) and (-524.61,-1918.17) .. (-524.61,-1918.17)
));
ATTR__id := "l248-3948-7524";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-573.93,-1889.73)
 -- (-564.64,-1933.40)
));
ATTR__id := "l249-4050-7530";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-569.22,-1883.22)
 -- (-539.71,-1925.34)
));
ATTR__id := "l251-4424-8196";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-511.76,-1781.55)
 .. controls (-508.17,-1784.45) and (-472.51,-1791.98) .. (-467.82,-1790.16)
));
ATTR__id := "l252-4140-8522";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-681.28,-1823.73)
 .. controls (-681.28,-1823.73) and (-683.38,-1843.78) .. (-649.55,-1858.40)
 .. controls (-642.93,-1861.26) and (-634.04,-1855.00) .. (-628.87,-1852.24)
 .. controls (-611.72,-1843.09) and (-602.42,-1834.90) .. (-602.42,-1834.90)
));
ATTR__id := "l688-3876-8270";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-648.89,-1765.99)
 -- (-619.93,-1809.13)
 -- (-580.57,-1774.96)
 -- (-618.14,-1737.52)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-471.09,-1674.30)
 .. controls (-447.67,-1673.91) and (-457.01,-1657.66) .. (-459.87,-1653.32)
 .. controls (-461.83,-1650.36) and (-463.44,-1645.01) .. (-472.45,-1647.53)
 .. controls (-486.76,-1651.53) and (-484.72,-1663.78) .. (-484.72,-1663.78)
));
ATTR__id := "l620-4610-8624";
ATTR__height := -1;
drawoptions();
l_rockborder(((-468.59,-1684.77)
 .. controls (-468.59,-1684.77) and (-487.97,-1712.75) .. (-471.39,-1727.84)
 .. controls (-454.81,-1742.92) and (-445.87,-1706.66) .. (-448.77,-1699.85)
));
ATTR__id := "l614-4454-8846";
ATTR__height := -1;
drawoptions();
l_rockborder(((-484.72,-1663.78)
 .. controls (-484.72,-1663.78) and (-485.58,-1674.48) .. (-471.09,-1674.30)
));
ATTR__id := "l609-4168-8172";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-602.42,-1834.90)
 -- (-540.12,-1858.83)
 .. controls (-540.12,-1858.83) and (-544.10,-1910.32) .. (-525.65,-1925.31)
 .. controls (-507.22,-1940.30) and (-405.42,-1737.78) .. (-405.42,-1737.78)
 .. controls (-405.42,-1737.78) and (-418.21,-1728.72) .. (-425.66,-1706.58)
 .. controls (-428.55,-1697.96) and (-443.36,-1694.79) .. (-448.77,-1699.85)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((-448.77,-1699.85)
 .. controls (-448.77,-1699.85) and (-450.92,-1673.92) .. (-468.59,-1684.77)
));
ATTR__id := "l610-4496-8810";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-468.59,-1684.77)
 -- (-471.09,-1674.30)
));
ATTR__id := "l611-4190-8982";
ATTR__height := -1;
drawoptions();
l_border_invisible(((-484.72,-1663.78)
 .. controls (-484.72,-1663.78) and (-497.94,-1638.07) .. (-516.62,-1642.68)
 .. controls (-535.28,-1647.28) and (-681.28,-1823.73) .. (-681.28,-1823.73)
));
ATTR__id := "l684-11582-29882";
ATTR__height := -1;
drawoptions();
l_border_invisible(((685.20,2121.38)
 .. controls (685.20,2121.38) and (776.66,2179.78) .. (780.24,2116.00)
 .. controls (783.83,2052.21) and (827.77,2160.32) .. (827.77,2160.32)
 -- (694.22,2207.49)
 -- cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((610.99,1435.62)
 .. controls (610.99,1435.62) and (601.05,1446.07) .. (596.54,1448.30)
 .. controls (592.00,1450.54) and (585.97,1452.34) .. (581.44,1454.26)
 .. controls (576.89,1456.19) and (573.48,1458.60) .. (567.07,1459.34)
 .. controls (560.65,1460.08) and (554.62,1463.84) .. (550.11,1457.62)
 .. controls (545.62,1451.42) and (544.86,1441.88) .. (544.47,1436.07)
 .. controls (544.08,1430.28) and (544.78,1422.42) .. (545.86,1416.65)
 .. controls (546.93,1410.91) and (545.55,1398.07) .. (545.55,1398.07)
));
ATTR__id := "l638-10708-27500";
ATTR__height := -1;
drawoptions();
l_border_visible(((538.11,1594.30)
 -- (677.36,1708.50)
));
ATTR__id := "l640-11146-27756";
ATTR__height := -1;
drawoptions();
l_border_visible(((631.51,1474.30)
 -- (734.27,1589.42)
 -- (725.79,1738.06)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((572.73,1458.19)
 .. controls (572.73,1458.19) and (573.44,1466.98) .. (576.04,1470.39)
 .. controls (578.63,1473.80) and (584.12,1479.41) .. (588.15,1480.00)
 .. controls (592.15,1480.59) and (597.13,1482.91) .. (605.42,1480.47)
 .. controls (613.63,1478.06) and (617.16,1477.47) .. (620.32,1476.85)
 .. controls (623.47,1476.23) and (632.16,1469.87) .. (632.16,1469.87)
));
ATTR__height := -1;
drawoptions();
l_flowstone(((554.62,1460.10)
 .. controls (554.62,1460.10) and (553.48,1465.09) .. (548.59,1467.62)
 .. controls (543.70,1470.14) and (537.81,1476.22) .. (529.82,1470.85)
 .. controls (521.97,1465.58) and (523.41,1468.02) .. (520.72,1460.64)
 .. controls (518.07,1453.38) and (517.67,1448.99) .. (516.89,1443.87)
 .. controls (516.11,1438.75) and (513.75,1438.96) .. (513.75,1433.65)
));
ATTR__id := "l14-9757-26365";
ATTR__height := -1;
drawoptions();
l_flowstone(((551.17,1481.73)
 .. controls (546.65,1483.80) and (538.73,1489.59) .. (533.45,1492.89)
 .. controls (528.12,1496.22) and (513.54,1500.75) .. (505.77,1501.52)
 .. controls (498.53,1502.24) and (487.77,1497.05) .. (482.41,1493.34)
 .. controls (477.12,1489.67) and (477.13,1485.46) .. (476.45,1480.93)
 .. controls (475.78,1476.41) and (471.97,1469.37) .. (471.64,1466.58)
 .. controls (471.30,1463.78) and (470.26,1458.14) .. (470.26,1458.14)
));
ATTR__id := "l13-9659-26066";
ATTR__height := -1;
drawoptions();
l_flowstone(((479.35,1399.94)
 .. controls (479.35,1399.94) and (474.11,1404.81) .. (471.04,1409.20)
 .. controls (467.98,1413.55) and (465.27,1416.64) .. (461.82,1419.73)
 .. controls (458.39,1422.81) and (454.68,1430.14) .. (455.79,1431.66)
 .. controls (456.89,1433.17) and (457.68,1435.11) .. (454.91,1439.52)
 .. controls (452.18,1443.88) and (447.56,1452.67) .. (454.75,1454.23)
 .. controls (461.82,1455.77) and (468.55,1462.01) .. (474.79,1459.06)
 .. controls (481.09,1456.08) and (482.41,1451.64) .. (482.41,1451.64)
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_flowstone(((484.82,1424.97)
 .. controls (485.10,1441.14) and (488.00,1448.66) .. (490.16,1450.47)
 .. controls (492.31,1452.27) and (496.33,1451.96) .. (496.33,1451.96)
 .. controls (496.33,1451.96) and (494.14,1461.06) .. (494.86,1466.64)
 .. controls (495.57,1472.22) and (503.98,1484.36) .. (517.10,1472.60)
 .. controls (529.12,1461.84) and (524.53,1466.29) .. (524.53,1466.29)
));
ATTR__id := "l211-10474-26546";
ATTR__height := -1;
drawoptions();
l_flowstone(((541.38,1487.53)
 .. controls (541.38,1487.53) and (540.99,1490.00) .. (544.34,1496.21)
 .. controls (547.69,1502.42) and (552.51,1511.95) .. (556.21,1514.47)
 .. controls (559.89,1516.97) and (565.64,1520.35) .. (572.75,1520.45)
 .. controls (579.72,1520.55) and (595.13,1520.71) .. (599.99,1515.64)
 .. controls (604.84,1510.57) and (612.23,1503.61) .. (615.20,1500.51)
 .. controls (618.17,1497.42) and (623.57,1489.22) .. (625.82,1486.51)
 .. controls (628.07,1483.80) and (631.51,1474.30) .. (631.51,1474.30)
));
ATTR__id := "l213-10126-26710";
ATTR__height := -1;
drawoptions();
l_border_invisible(((538.11,1594.30)
 .. controls (538.11,1594.30) and (529.16,1584.78) .. (527.46,1576.14)
 .. controls (525.74,1567.43) and (520.55,1563.96) .. (527.07,1558.38)
 .. controls (533.55,1552.84) and (534.02,1555.78) .. (538.97,1549.47)
 .. controls (543.97,1543.10) and (545.11,1539.83) .. (545.57,1532.90)
 .. controls (546.03,1525.93) and (546.78,1524.70) .. (550.92,1521.03)
 .. controls (555.06,1517.35) and (559.20,1513.26) .. (559.20,1513.26)
));
ATTR__id := "l208-11076-27806";
ATTR__height := -1;
drawoptions();
l_flowstone(((716.22,1780.42)
 .. controls (716.22,1780.42) and (713.17,1782.24) .. (708.49,1780.98)
 .. controls (703.81,1779.73) and (700.75,1777.75) .. (699.49,1771.07)
 .. controls (698.22,1764.40) and (697.86,1759.35) .. (699.66,1755.22)
 .. controls (701.47,1751.10) and (704.17,1748.42) .. (707.06,1745.38)
 .. controls (709.94,1742.35) and (713.56,1738.61) .. (718.24,1738.61)
 .. controls (722.92,1738.61) and (725.79,1738.06) .. (725.79,1738.06)
));
ATTR__id := "l209-10984-27732";
ATTR__height := -1;
drawoptions();
l_border_invisible(((711.43,1741.59)
 .. controls (711.43,1741.59) and (708.87,1740.74) .. (706.35,1738.95)
 .. controls (703.83,1737.16) and (705.28,1735.92) .. (702.59,1731.80)
 .. controls (699.89,1727.69) and (694.85,1724.62) .. (691.97,1722.10)
 .. controls (689.08,1719.57) and (687.10,1717.94) .. (685.66,1715.77)
 .. controls (684.22,1713.61) and (679.71,1709.78) .. (677.36,1708.50)
));
ATTR__id := "l643-11124-27794";
ATTR__height := -1;
drawoptions();
l_border_invisible(((725.79,1738.06)
 .. controls (718.52,1738.07) and (711.43,1741.59) .. (711.43,1741.59)
));
ATTR__id := "l210-10833-28559";
ATTR__height := -1;
drawoptions();
l_border_invisible(((643.42,1900.60)
 .. controls (645.76,1898.44) and (653.32,1886.39) .. (654.76,1884.24)
 .. controls (656.20,1882.08) and (658.21,1878.94) .. (662.86,1876.52)
 .. controls (670.43,1872.57) and (662.87,1873.65) .. (674.38,1876.52)
 .. controls (677.98,1877.42) and (684.10,1875.43) .. (688.96,1876.68)
 .. controls (693.81,1877.93) and (700.65,1882.42) .. (700.65,1882.42)
));
ATTR__id := "l648-10804-28026";
ATTR__height := -1;
drawoptions();
l_border_invisible(((643.42,1900.60)
 -- (677.36,1708.50)
));
ATTR__id := "l650-11042-28484";
ATTR__height := -1;
drawoptions();
l_border_invisible(((716.22,1780.42)
 .. controls (716.22,1780.42) and (716.82,1839.68) .. (700.65,1882.42)
));
ATTR__id := "l645-11004-29038";
ATTR__height := -1;
drawoptions();
l_border_invisible(((700.65,1882.42)
 -- (701.23,1990.19)
));
ATTR__id := "l213-10786-29310";
ATTR__height := -1;
drawoptions();
l_border_invisible(((646.50,2000.80)
 .. controls (646.50,2000.80) and (654.43,2006.23) .. (656.95,2008.04)
 .. controls (659.47,2009.85) and (665.06,2013.65) .. (671.36,2013.66)
 .. controls (677.66,2013.66) and (676.04,2014.20) .. (680.18,2013.29)
 .. controls (684.32,2012.39) and (690.80,2012.73) .. (693.13,2008.05)
 .. controls (695.47,2003.36) and (701.23,1990.19) .. (701.23,1990.19)
));
ATTR__id := "l646-10658-28742";
ATTR__height := -1;
drawoptions();
l_border_invisible(((643.42,1900.60)
 .. controls (643.42,1900.60) and (606.67,1951.65) .. (646.50,2000.80)
));
ATTR__id := "l290-11258-29489";
ATTR__height := -1;
drawoptions();
l_border_visible(((701.23,1990.19)
 .. controls (701.23,1990.19) and (701.41,1997.05) .. (714.20,2009.85)
 .. controls (726.98,2022.66) and (742.82,2020.65) .. (746.41,2039.53)
 .. controls (750.00,2058.39) and (755.40,2079.07) .. (758.81,2081.76)
 .. controls (762.23,2084.46) and (759.72,2089.51) .. (761.70,2102.30)
));
ATTR__id := "l289-10912-29738";
ATTR__height := -1;
drawoptions();
l_border_visible(((646.50,2000.80)
 .. controls (648.48,2006.03) and (667.21,2035.23) .. (672.25,2046.91)
 .. controls (677.28,2058.59) and (687.89,2101.93) .. (689.88,2107.51)
 .. controls (691.86,2113.10) and (701.40,2123.74) .. (701.40,2123.74)
));
ATTR__id := "l216-10266-25887";
ATTR__height := -1;
drawoptions();
l_border_invisible(((552.87,1371.97)
 -- (570.54,1381.34)
 -- (581.50,1364.96)
));
ATTR__id := "l586-9470-25910";
ATTR__height := -1;
drawoptions();
l_border_invisible(((336.76,1251.64)
 .. controls (336.76,1251.64) and (341.53,1226.87) .. (340.84,1222.91)
 .. controls (333.49,1180.80) and (425.60,1218.89) .. (425.60,1218.89)
 -- (466.73,1247.46)
 .. controls (466.73,1247.46) and (505.39,1265.24) .. (480.82,1347.21)
 .. controls (453.74,1437.56) and (390.88,1378.16) .. (390.88,1378.16)
 -- cycle
));
ATTR__id := "l588-8912-24928";
ATTR__height := -1;
drawoptions();
l_border_invisible(((322.90,1212.71)
 .. controls (322.90,1212.71) and (304.10,1106.14) .. (355.99,1093.02)
 .. controls (412.67,1078.70) and (384.30,1129.29) .. (391.56,1146.08)
 .. controls (399.44,1164.29) and (409.05,1184.19) .. (379.69,1195.09)
 .. controls (325.12,1215.35) and (370.29,1242.11) .. (333.97,1228.58)
 .. controls (331.93,1227.82) and (322.90,1212.71) .. cycle
));
ATTR__id := "l593-9608-22152";
ATTR__height := -1;
drawoptions();
l_border_invisible(((485.52,783.45)
 .. controls (485.52,783.45) and (303.21,479.71) .. (322.49,457.09)
));
ATTR__id := "l595-8816-19340";
ATTR__height := -1;
drawoptions();
l_border_invisible(((307.57,285.25)
 .. controls (307.57,285.25) and (284.53,55.02) .. (396.50,244.80)
));
ATTR__id := "l597-10410-22954";
ATTR__height := -1;
drawoptions();
l_border_invisible(((312.81,1124.43)
 .. controls (312.81,1124.43) and (377.16,1061.66) .. (450.99,1097.20)
 .. controls (525.53,1133.09) and (510.29,1152.21) .. (549.46,1142.52)
 .. controls (588.60,1132.83) and (629.28,1085.59) .. (635.08,1074.65)
 .. controls (640.91,1063.67) and (659.21,1013.75) .. (642.24,985.58)
 .. controls (625.35,957.53) and (620.68,906.17) .. (607.02,891.85)
 .. controls (593.36,877.52) and (591.24,851.37) .. (588.01,841.14)
));
ATTR__id := "l601-8802-24326";
ATTR__height := -1;
drawoptions();
l_border_invisible(((312.81,1124.43)
 .. controls (312.81,1124.43) and (294.37,1075.83) .. (326.81,1072.42)
 .. controls (359.26,1069.01) and (362.88,1066.39) .. (362.88,1066.39)
));
ATTR__id := "l602-9962-22858";
ATTR__height := -1;
drawoptions();
l_border_invisible(((519.54,864.09)
 -- (485.52,783.45)
));
ATTR__id := "l603-8850-20564";
ATTR__height := -1;
drawoptions();
l_border_invisible(((322.49,457.09)
 -- (274.08,341.88)
));
ATTR__id := "l7-11386-29954";
ATTR__height := -1;
drawoptions();
l_floorstep(((761.70,2102.30)
 .. controls (761.70,2102.30) and (785.21,2144.93) .. (753.43,2142.49)
));
ATTR__id := "l6-10998-29848";
ATTR__height := -1;
drawoptions();
l_floorstep(((701.40,2123.74)
 .. controls (697.08,2113.64) and (695.27,2104.45) .. (721.92,2077.82)
 .. controls (747.24,2052.52) and (761.70,2102.30) .. (761.70,2102.30)
));
ATTR__id := "l5-11066-29995";
ATTR__height := -1;
drawoptions();
l_floorstep(((753.43,2142.49)
 .. controls (721.71,2140.09) and (705.73,2133.84) .. (701.40,2123.74)
));
ATTR__id := "l591-10140-23538";
ATTR__height := -1;
drawoptions();
l_border_visible(((555.45,1011.03)
 -- (519.54,864.09)
));
endfig;
beginfig(14);
draw_upscrap(1)(1,((-77.80,-1335.57)
 .. controls (-73.66,-1326.93) and (-80.85,-1310.36) .. (-72.93,-1290.19)
 .. controls (-65.01,-1270.03) and (-54.93,-1252.02) .. (-58.53,-1230.43)
 .. controls (-62.13,-1208.83) and (-65.02,-1182.20) .. (-68.62,-1171.41)
 .. controls (-72.23,-1160.62) and (-71.50,-1138.29) .. (-70.78,-1125.33)
 .. controls (-70.05,-1112.36) and (-71.48,-1088.60) .. (-59.96,-1071.32)
 .. controls (-48.44,-1054.04) and (-34.76,-1019.48) .. (-14.60,-1003.64)
 .. controls (5.56,-987.79) and (46.59,-945.33) .. (53.79,-932.37)
 .. controls (60.99,-919.40) and (97.72,-886.27) .. (103.48,-873.31)
 .. controls (109.24,-860.36) and (132.28,-816.44) .. (135.88,-804.93)
 .. controls (139.47,-793.41) and (145.94,-724.30) .. (187.71,-693.33)
 .. controls (229.47,-662.38) and (229.47,-624.94) .. (235.23,-614.86)
 .. controls (240.99,-604.78) and (243.87,-552.23) .. (243.87,-547.91)
 .. controls (243.87,-543.59) and (246.03,-519.83) .. (254.67,-504.71)
 .. controls (263.31,-489.59) and (278.42,-468.71) .. (285.62,-457.91)
 .. controls (292.82,-447.11) and (309.38,-415.43) .. (315.14,-408.95)
 .. controls (320.90,-402.47) and (347.54,-384.47) .. (356.18,-374.39)
 .. controls (364.82,-364.31) and (438.26,-284.39) .. (444.74,-272.15)
 .. controls (451.21,-259.90) and (456.97,-236.86) .. (461.29,-225.34)
 .. controls (465.61,-213.82) and (477.13,-203.75) .. (483.61,-194.39)
 .. controls (490.09,-185.04) and (510.97,-159.13) .. (510.97,-148.33)
 .. controls (510.97,-137.53) and (519.61,-108.02) .. (529.69,-91.47)
 .. controls (539.77,-74.91) and (544.10,-36.03) .. (544.10,-30.27)
 .. controls (544.10,-24.51) and (549.86,23.73) .. (547.70,35.97)
 .. controls (545.54,48.21) and (537.62,71.26) .. (546.26,90.69)
 .. controls (554.90,110.13) and (570.02,138.93) .. (576.50,150.45)
 .. controls (582.98,161.96) and (598.81,189.31) .. (597.37,201.55)
 .. controls (595.93,213.79) and (593.95,235.92) .. (568.03,243.14)
 .. controls (542.12,250.36) and (505.94,254.15) .. (493.70,253.43)
 .. controls (481.46,252.71) and (452.67,247.68) .. (437.55,266.41)
 .. controls (422.43,285.13) and (419.54,281.53) .. (417.38,287.29)
),
1,((417.38,287.29)
 .. controls (417.38,287.29) and (411.62,294.66) .. (413.60,307.26)
 .. controls (415.58,319.85) and (423.31,337.47) .. (421.51,345.20)
 .. controls (419.71,352.94) and (417.18,361.21) .. (418.98,370.57)
 .. controls (420.78,379.93) and (425.10,398.65) .. (425.46,402.08)
 .. controls (425.82,405.50) and (424.38,424.95) .. (435.90,432.48)
 .. controls (447.41,440.02) and (462.52,458.88) .. (463.42,460.68)
 .. controls (464.32,462.48) and (487.00,488.55) .. (492.58,494.49)
 .. controls (498.16,500.43) and (519.05,527.83) .. (521.21,532.35)
 .. controls (523.38,536.86) and (547.15,579.92) .. (548.95,585.67)
 .. controls (550.75,591.43) and (555.23,608.85) .. (555.58,630.94)
 .. controls (555.93,653.06) and (554.31,673.06) .. (554.50,685.32)
 .. controls (554.68,697.58) and (554.86,716.13) .. (556.84,726.37)
 .. controls (558.81,736.61) and (570.14,775.61) .. (572.48,782.28)
 .. controls (574.83,788.96) and (583.13,812.82) .. (584.76,818.79)
 .. controls (586.38,824.74) and (586.75,833.58) .. (588.01,841.14)
 .. controls (589.26,848.68) and (594.29,855.84) .. (603.63,864.77)
 .. controls (612.97,873.69) and (632.55,900.36) .. (635.25,905.92)
 .. controls (637.94,911.47) and (656.80,953.43) .. (658.60,963.86)
 .. controls (660.40,974.31) and (666.39,1018.23) .. (664.96,1032.17)
 .. controls (663.54,1046.06) and (653.41,1078.08) .. (632.08,1095.26)
 .. controls (610.77,1112.41) and (555.36,1152.27) .. (550.88,1154.67)
 .. controls (546.40,1157.07) and (525.37,1173.54) .. (496.88,1160.31)
 .. controls (468.34,1147.07) and (447.30,1136.79) .. (444.06,1134.48)
 .. controls (440.83,1132.16) and (412.99,1114.81) .. (411.48,1155.18)
 .. controls (409.98,1195.67) and (408.01,1202.53) .. (409.98,1208.45)
 .. controls (411.96,1214.39) and (410.50,1224.63) .. (425.65,1234.95)
 .. controls (440.66,1245.17) and (456.55,1255.39) .. (457.61,1260.52)
 .. controls (458.66,1265.63) and (468.30,1310.70) .. (469.96,1318.67)
 .. controls (471.63,1326.65) and (473.57,1359.46) .. (474.27,1369.36)
 .. controls (474.99,1379.46) and (477.90,1416.44) .. (480.12,1421.00)
 .. controls (482.34,1425.53) and (483.74,1447.15) .. (502.35,1437.73)
 .. controls (522.23,1427.66) and (527.56,1425.82) .. (530.00,1423.56)
 .. controls (532.42,1421.31) and (541.86,1410.44) .. (542.93,1406.76)
 .. controls (543.99,1403.11) and (545.25,1401.85) .. (549.15,1399.20)
 .. controls (553.05,1396.56) and (558.10,1396.38) .. (559.76,1392.86)
 .. controls (561.40,1389.39) and (563.13,1387.56) .. (561.41,1381.75)
 .. controls (559.21,1374.31) and (559.26,1373.28) .. (555.48,1368.71)
),
1,((579.00,1358.63)
 .. controls (579.00,1358.63) and (577.83,1360.50) .. (576.33,1374.57)
 .. controls (575.42,1383.13) and (580.44,1391.03) .. (583.99,1397.93)
 .. controls (587.58,1404.89) and (604.52,1430.29) .. (610.78,1442.85)
 .. controls (616.97,1455.31) and (635.29,1485.00) .. (640.49,1489.33)
 .. controls (645.69,1493.68) and (660.77,1518.68) .. (663.45,1524.28)
 .. controls (666.13,1529.88) and (671.77,1555.70) .. (677.55,1571.37)
 .. controls (683.21,1586.68) and (695.94,1611.23) .. (699.51,1615.09)
 .. controls (703.08,1618.95) and (708.99,1635.90) .. (715.12,1649.14)
 .. controls (721.31,1662.47) and (722.27,1679.11) .. (723.36,1686.37)
 .. controls (724.45,1693.60) and (722.09,1710.46) .. (724.41,1718.83)
 .. controls (726.72,1727.19) and (719.28,1759.71) .. (718.38,1765.10)
 .. controls (717.48,1770.50) and (711.92,1788.93) .. (711.22,1803.59)
 .. controls (710.52,1818.24) and (705.51,1842.27) .. (703.89,1844.26)
 .. controls (702.27,1846.25) and (698.31,1860.65) .. (698.31,1863.89)
 .. controls (698.31,1867.12) and (697.95,1884.05) .. (696.16,1889.10)
 .. controls (694.36,1894.16) and (693.31,1909.35) .. (692.06,1918.39)
 .. controls (690.81,1927.42) and (693.33,1936.06) .. (694.22,1941.63)
 .. controls (695.12,1947.20) and (694.39,1968.58) .. (696.00,1976.32)
 .. controls (697.63,1984.06) and (697.45,1993.98) .. (699.25,2002.45)
 .. controls (701.05,2010.92) and (707.89,2013.46) .. (717.44,2017.61)
 .. controls (726.98,2021.76) and (737.95,2043.50) .. (740.47,2049.24)
 .. controls (742.99,2054.99) and (756.47,2083.57) .. (757.38,2088.97)
 .. controls (758.28,2094.37) and (775.21,2135.47) .. (778.10,2141.79)
 .. controls (780.98,2148.10) and (789.81,2159.46) .. (791.07,2164.68)
),
1,((711.51,2186.46)
 .. controls (709.89,2181.24) and (707.18,2168.09) .. (706.64,2158.00)
 .. controls (706.10,2147.90) and (701.58,2121.39) .. (698.88,2115.98)
 .. controls (696.18,2110.58) and (683.57,2077.10) .. (682.32,2069.37)
 .. controls (681.06,2061.64) and (676.92,2049.96) .. (677.11,2046.73)
 .. controls (677.29,2043.50) and (676.57,2034.70) .. (668.30,2026.25)
 .. controls (660.01,2017.78) and (646.50,2000.80) .. (641.27,1978.06)
 .. controls (636.04,1955.35) and (629.56,1943.63) .. (631.90,1937.33)
 .. controls (634.24,1931.04) and (632.08,1931.21) .. (634.96,1929.78)
 .. controls (637.84,1928.35) and (638.38,1927.09) .. (639.64,1920.79)
 .. controls (640.90,1914.48) and (647.20,1899.71) .. (647.74,1892.68)
 .. controls (648.27,1885.66) and (652.78,1874.35) .. (652.07,1864.31)
 .. controls (651.36,1854.28) and (653.17,1851.60) .. (654.61,1849.09)
 .. controls (656.06,1846.59) and (655.88,1840.66) .. (655.70,1834.72)
 .. controls (655.52,1828.77) and (657.14,1828.78) .. (657.68,1827.16)
 .. controls (658.22,1825.53) and (660.37,1820.29) .. (661.44,1816.12)
 .. controls (662.51,1811.95) and (666.05,1788.86) .. (668.92,1785.04)
 .. controls (671.79,1781.22) and (678.05,1755.17) .. (679.13,1748.69)
 .. controls (680.21,1742.23) and (680.24,1717.50) .. (681.33,1715.18)
 .. controls (682.41,1712.87) and (685.13,1705.73) .. (684.05,1702.48)
 .. controls (682.97,1699.23) and (676.81,1684.69) .. (673.91,1681.75)
 .. controls (671.02,1678.81) and (656.91,1660.02) .. (653.84,1654.22)
 .. controls (650.78,1648.43) and (637.79,1632.29) .. (633.46,1628.26)
 .. controls (629.11,1624.22) and (610.14,1617.80) .. (601.30,1615.60)
 .. controls (592.48,1613.41) and (571.29,1606.87) .. (567.71,1603.88)
 .. controls (564.13,1600.90) and (516.91,1579.89) .. (512.08,1573.73)
 .. controls (507.24,1567.59) and (470.67,1526.49) .. (466.69,1516.93)
 .. controls (462.78,1507.53) and (451.44,1483.25) .. (449.74,1478.00)
 .. controls (448.02,1472.72) and (448.43,1468.93) .. (446.30,1466.68)
 .. controls (444.15,1464.41) and (439.08,1463.28) .. (435.30,1457.98)
 .. controls (431.45,1452.58) and (420.21,1424.77) .. (418.34,1420.57)
 .. controls (416.47,1416.38) and (406.65,1383.92) .. (404.67,1376.52)
 .. controls (402.70,1369.20) and (396.52,1337.40) .. (394.63,1331.22)
 .. controls (392.74,1325.05) and (388.50,1304.36) .. (385.66,1299.08)
 .. controls (382.80,1293.75) and (364.18,1267.52) .. (360.74,1261.88)
 .. controls (357.31,1256.25) and (345.96,1246.14) .. (340.03,1241.33)
 .. controls (334.12,1236.53) and (281.65,1188.27) .. (272.81,1180.80)
),
1,((284.65,1087.36)
 .. controls (325.73,1080.33) and (357.81,1074.40) .. (362.51,1070.32)
 .. controls (367.21,1066.25) and (377.88,1058.68) .. (382.40,1052.64)
 .. controls (386.92,1046.59) and (397.56,1033.70) .. (400.08,1031.53)
 .. controls (402.60,1029.37) and (405.66,1028.84) .. (410.34,1028.48)
 .. controls (415.02,1028.11) and (419.69,1026.64) .. (421.66,1025.35)
 .. controls (423.64,1024.07) and (437.98,1013.44) .. (443.90,1001.80)
 .. controls (449.81,990.19) and (461.50,982.94) .. (464.56,979.33)
 .. controls (467.62,975.73) and (475.72,968.36) .. (476.27,966.03)
 .. controls (476.81,963.69) and (482.03,958.68) .. (487.25,962.64)
 .. controls (492.47,966.61) and (507.96,974.38) .. (510.65,977.08)
 .. controls (513.35,979.78) and (524.32,992.87) .. (525.04,997.88)
 .. controls (525.75,1002.89) and (535.63,1021.17) .. (537.61,1023.51)
 .. controls (539.59,1025.84) and (541.38,1032.66) .. (544.26,1033.92)
 .. controls (547.14,1035.19) and (564.61,1041.02) .. (565.16,1027.02)
 .. controls (565.72,1013.03) and (563.56,1003.71) .. (563.39,999.77)
 .. controls (563.22,995.84) and (563.98,976.74) .. (564.18,970.32)
 .. controls (564.37,963.90) and (564.05,951.23) .. (563.33,946.05)
 .. controls (562.62,940.85) and (561.36,929.35) .. (558.48,923.39)
 .. controls (555.59,917.42) and (549.27,904.38) .. (545.12,898.94)
 .. controls (540.98,893.51) and (534.31,889.52) .. (531.24,885.91)
 .. controls (528.18,882.30) and (526.56,879.05) .. (524.22,872.74)
 .. controls (521.88,866.44) and (521.88,849.54) .. (519.72,842.33)
 .. controls (517.56,835.13) and (513.06,821.62) .. (507.11,811.89)
 .. controls (501.17,802.16) and (486.96,777.00) .. (482.65,769.99)
 .. controls (478.33,762.99) and (468.97,748.60) .. (467.90,744.65)
 .. controls (466.82,740.69) and (455.29,730.40) .. (454.93,720.69)
 .. controls (454.58,710.98) and (452.41,688.83) .. (450.97,684.32)
 .. controls (449.53,679.82) and (443.96,646.33) .. (443.06,639.49)
 .. controls (442.16,632.66) and (436.05,605.13) .. (425.78,595.40)
 .. controls (415.52,585.67) and (397.34,561.38) .. (393.02,555.80)
 .. controls (388.70,550.22) and (365.13,531.70) .. (359.73,519.66)
 .. controls (354.34,507.63) and (345.88,488.58) .. (342.29,481.21)
 .. controls (338.69,473.84) and (325.37,458.54) .. (323.75,450.62)
 .. controls (322.13,442.71) and (318.53,422.19) .. (318.17,415.53)
 .. controls (317.81,408.87) and (317.46,388.35) .. (310.80,374.67)
 .. controls (304.14,360.99) and (302.34,339.76) .. (301.80,332.38)
 .. controls (301.26,325.00) and (303.61,294.78) .. (304.69,292.08)
 .. controls (305.77,289.38) and (306.31,292.62) .. (309.73,287.23)
 .. controls (313.15,281.83) and (315.68,271.21) .. (313.88,265.63)
 .. controls (312.07,260.05) and (307.76,238.62) .. (309.38,233.58)
 .. controls (311.00,228.54) and (314.06,211.08) .. (316.22,206.94)
 .. controls (318.38,202.80) and (318.02,184.80) .. (328.28,183.73)
 .. controls (338.54,182.65) and (346.46,185.18) .. (353.84,196.52)
 .. controls (361.22,207.87) and (368.78,214.71) .. (372.74,220.30)
 .. controls (376.70,225.88) and (384.98,237.41) .. (388.40,239.75)
 .. controls (391.82,242.10) and (391.82,247.14) .. (396.86,248.58)
 .. controls (401.91,250.02) and (405.87,252.37) .. (408.75,252.73)
),
1,((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
),
1,((-206.45,-1279.69)
 .. controls (-208.25,-1286.16) and (-215.81,-1309.37) .. (-215.81,-1315.14)
 .. controls (-215.81,-1320.90) and (-222.30,-1354.93) .. (-224.46,-1361.05)
 .. controls (-226.63,-1367.18) and (-231.67,-1374.38) .. (-233.83,-1379.60)
 .. controls (-235.99,-1384.81) and (-250.73,-1417.37) .. (-253.25,-1424.20)
 .. controls (-255.76,-1431.04) and (-266.73,-1457.66) .. (-268.89,-1461.08)
 .. controls (-271.05,-1464.49) and (-287.24,-1470.96) .. (-297.85,-1473.65)
 .. controls (-308.46,-1476.34) and (-336.52,-1484.95) .. (-344.80,-1487.28)
 .. controls (-353.07,-1489.61) and (-395.51,-1512.40) .. (-403.96,-1519.05)
 .. controls (-412.41,-1525.69) and (-442.43,-1552.82) .. (-447.11,-1559.65)
 .. controls (-451.79,-1566.49) and (-485.81,-1602.32) .. (-489.61,-1612.24)
 .. controls (-493.41,-1622.17) and (-503.86,-1636.77) .. (-507.11,-1641.82)
 .. controls (-510.35,-1646.86) and (-523.65,-1658.71) .. (-527.79,-1670.77)
 .. controls (-531.92,-1682.82) and (-547.53,-1710.11) .. (-553.81,-1716.74)
 .. controls (-560.09,-1723.37) and (-573.72,-1725.62) .. (-578.20,-1726.13)
 .. controls (-582.68,-1726.64) and (-596.83,-1730.32) .. (-610.45,-1746.41)
 .. controls (-624.04,-1762.48) and (-631.37,-1770.50) .. (-636.19,-1777.64)
 .. controls (-641.01,-1784.78) and (-646.55,-1786.87) .. (-658.85,-1804.68)
 .. controls (-671.13,-1822.46) and (-677.71,-1829.53) .. (-679.65,-1839.01)
 .. controls (-681.59,-1848.48) and (-692.23,-1872.52) .. (-695.60,-1879.47)
 .. controls (-698.98,-1886.42) and (-706.63,-1898.35) .. (-711.63,-1905.83)
 .. controls (-716.63,-1913.33) and (-720.22,-1921.24) .. (-722.06,-1927.95)
 .. controls (-723.90,-1934.67) and (-725.76,-1942.68) .. (-725.76,-1942.68)
),
1,((-725.57,-1941.40)
 .. controls (-727.74,-1948.26) and (-744.88,-1958.52) .. (-750.06,-1958.79)
 .. controls (-755.22,-1959.06) and (-774.12,-1958.31) .. (-778.73,-1960.18)
 .. controls (-783.33,-1962.05) and (-795.04,-1983.81) .. (-798.09,-1988.10)
 .. controls (-801.16,-1992.41) and (-806.46,-1998.75) .. (-809.82,-2001.52)
 .. controls (-813.21,-2004.32) and (-826.51,-2014.69) .. (-828.52,-2015.66)
),
1,((-784.78,-2051.57)
 .. controls (-782.11,-2049.49) and (-776.59,-2047.64) .. (-770.39,-2047.62)
 .. controls (-764.37,-2047.60) and (-765.31,-2049.44) .. (-757.03,-2047.86)
 .. controls (-748.81,-2046.30) and (-751.59,-2049.48) .. (-750.48,-2052.40)
 .. controls (-749.36,-2055.35) and (-750.70,-2061.51) .. (-750.93,-2067.04)
 .. controls (-751.15,-2072.72) and (-753.83,-2091.35) .. (-754.27,-2094.49)
 .. controls (-754.71,-2097.64) and (-763.06,-2145.64) .. (-765.11,-2157.38)
 .. controls (-767.11,-2168.82) and (-765.59,-2196.14) .. (-764.51,-2200.64)
),
1,((-764.51,-2200.64)
 -- (-764.51,-2200.64)),
1,((-767.75,-2196.14)
 .. controls (-766.31,-2198.84) and (-761.63,-2202.61) .. (-759.27,-2204.02)
 .. controls (-756.91,-2205.43) and (-752.54,-2207.33) .. (-750.17,-2207.11)
 .. controls (-747.81,-2206.89) and (-746.53,-2207.76) .. (-741.07,-2204.60)
 .. controls (-735.61,-2201.44) and (-727.08,-2200.24) .. (-725.62,-2196.62)
 .. controls (-724.16,-2192.98) and (-721.90,-2193.48) .. (-720.92,-2192.98)
 .. controls (-719.48,-2192.26) and (-716.53,-2192.64) .. (-714.48,-2194.49)
 .. controls (-713.06,-2195.78) and (-710.09,-2198.70) .. (-709.15,-2200.54)
 .. controls (-707.19,-2204.36) and (-706.30,-2206.17) .. (-702.20,-2206.24)
 .. controls (-698.11,-2206.31) and (-695.08,-2204.22) .. (-691.17,-2202.31)
 .. controls (-687.25,-2200.39) and (-684.39,-2199.35) .. (-681.88,-2198.10)
 .. controls (-679.37,-2196.86) and (-673.79,-2195.24) .. (-673.79,-2195.24)
),
1,((-676.94,-2196.59)
 .. controls (-675.68,-2192.27) and (-670.98,-2177.07) .. (-666.01,-2169.33)
 .. controls (-661.01,-2161.54) and (-650.92,-2142.57) .. (-647.94,-2137.73)
 .. controls (-644.97,-2132.90) and (-629.07,-2103.25) .. (-627.79,-2100.33)
 .. controls (-626.50,-2097.42) and (-621.15,-2070.78) .. (-615.30,-2050.56)
 .. controls (-609.50,-2030.48) and (-616.15,-2008.59) .. (-617.07,-2006.28)
 .. controls (-617.99,-2003.97) and (-619.57,-1988.89) .. (-619.24,-1985.70)
 .. controls (-618.91,-1982.51) and (-612.59,-1969.81) .. (-611.21,-1965.58)
 .. controls (-609.82,-1961.35) and (-601.59,-1948.74) .. (-597.00,-1944.58)
),
1,((-597.00,-1944.58)
 .. controls (-594.89,-1941.95) and (-590.31,-1936.00) .. (-585.51,-1932.67)
 .. controls (-580.69,-1929.33) and (-572.62,-1926.66) .. (-567.93,-1925.92)
 .. controls (-563.23,-1925.18) and (-543.52,-1917.47) .. (-540.28,-1915.67)
 .. controls (-537.04,-1913.87) and (-519.29,-1903.54) .. (-514.81,-1899.25)
 .. controls (-510.32,-1894.95) and (-502.22,-1875.86) .. (-499.68,-1868.81)
 .. controls (-497.14,-1861.77) and (-491.75,-1846.48) .. (-490.68,-1841.10)
 .. controls (-489.62,-1835.73) and (-488.39,-1822.28) .. (-487.49,-1817.42)
 .. controls (-486.59,-1812.56) and (-482.98,-1803.54) .. (-480.27,-1798.31)
 .. controls (-477.57,-1793.08) and (-469.08,-1783.13) .. (-462.40,-1777.70)
 .. controls (-455.72,-1772.27) and (-441.83,-1763.22) .. (-438.04,-1761.06)
 .. controls (-434.26,-1758.89) and (-425.43,-1750.59) .. (-422.72,-1746.81)
 .. controls (-420.02,-1743.03) and (-410.12,-1730.42) .. (-406.51,-1727.72)
 .. controls (-402.91,-1725.01) and (-390.48,-1710.23) .. (-386.69,-1707.53)
 .. controls (-382.91,-1704.82) and (-367.60,-1691.31) .. (-359.68,-1682.67)
 .. controls (-351.77,-1674.04) and (-341.34,-1665.06) .. (-335.04,-1662.37)
 .. controls (-328.75,-1659.68) and (-308.09,-1646.05) .. (-304.13,-1642.46)
 .. controls (-300.18,-1638.88) and (-272.67,-1617.86) .. (-266.37,-1612.64)
 .. controls (-260.07,-1607.42) and (-240.99,-1592.66) .. (-234.69,-1587.81)
 .. controls (-228.40,-1582.95) and (-191.93,-1545.98) .. (-187.61,-1542.02)
 .. controls (-183.29,-1538.07) and (-177.53,-1520.25) .. (-174.65,-1512.14)
 .. controls (-171.76,-1504.03) and (-157.69,-1480.59) .. (-155.71,-1476.45)
 .. controls (-153.73,-1472.30) and (-131.95,-1430.55) .. (-128.71,-1425.51)
 .. controls (-125.47,-1420.47) and (-116.29,-1409.14) .. (-113.77,-1405.18)
 .. controls (-111.25,-1401.22) and (-90.93,-1371.01) .. (-89.49,-1364.36)
 .. controls (-88.06,-1357.71) and (-79.42,-1340.62) .. (-77.80,-1335.57)
));
draw_upscrap(1)(1,((527.92,1571.09)
 -- (527.92,1571.09)));
draw_upscrap(0)(1,((-672.21,-1910.63)
 .. controls (-672.21,-1910.63) and (-672.34,-1899.41) .. (-672.51,-1893.45)
 .. controls (-672.68,-1887.50) and (-673.03,-1872.55) .. (-670.72,-1863.06)
 .. controls (-668.42,-1853.57) and (-660.96,-1835.91) .. (-660.43,-1830.71)
 .. controls (-659.90,-1825.50) and (-634.40,-1792.59) .. (-631.01,-1786.70)
 .. controls (-627.61,-1780.80) and (-607.76,-1761.38) .. (-600.43,-1754.07)
 .. controls (-593.08,-1746.74) and (-577.86,-1748.49) .. (-570.51,-1747.64)
 .. controls (-563.17,-1746.79) and (-546.68,-1753.20) .. (-540.05,-1757.57)
 .. controls (-533.43,-1761.94) and (-530.91,-1760.15) .. (-524.26,-1757.47)
 .. controls (-517.61,-1754.78) and (-512.58,-1755.52) .. (-512.58,-1755.52)
),
1,((-512.58,-1755.52)
 .. controls (-509.71,-1754.80) and (-506.13,-1763.12) .. (-505.97,-1767.46)
 .. controls (-505.80,-1771.80) and (-507.27,-1784.99) .. (-506.74,-1788.06)
 .. controls (-506.21,-1791.13) and (-500.27,-1803.92) .. (-499.19,-1808.23)
 .. controls (-498.11,-1812.55) and (-509.23,-1829.06) .. (-512.28,-1834.25)
 .. controls (-515.32,-1839.45) and (-528.27,-1855.09) .. (-532.60,-1862.12)
 .. controls (-536.92,-1869.14) and (-548.58,-1875.91) .. (-556.29,-1880.92)
 .. controls (-564.03,-1885.94) and (-571.63,-1896.28) .. (-575.61,-1899.91)
 .. controls (-579.59,-1903.54) and (-594.66,-1912.65) .. (-599.47,-1914.73)
 .. controls (-604.27,-1916.80) and (-630.55,-1921.17) .. (-646.54,-1925.79)
 .. controls (-662.68,-1930.45) and (-662.82,-1925.80) .. (-665.67,-1923.96)
 .. controls (-668.52,-1922.11) and (-671.33,-1913.91) .. (-672.21,-1910.63)
));
draw_downscrap;
endfig;
beginfig(15);
ATTR__id := "";
current_src := "Romeo_entrance.th2 [161]";
string area_border[];
area_border[1] := "l588-8912-24928";
drawoptions();
a_blocks(buildcycle(((322.90,1212.71)
 .. controls (322.90,1212.71) and (304.10,1106.14) .. (355.99,1093.02)
 .. controls (412.67,1078.70) and (384.30,1129.29) .. (391.56,1146.08)
 .. controls (399.44,1164.29) and (409.05,1184.19) .. (379.69,1195.09)
 .. controls (325.12,1215.35) and (370.29,1242.11) .. (333.97,1228.58)
 .. controls (331.93,1227.82) and (322.90,1212.71) .. cycle
)));
ATTR__id := "l260-3396-6065";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-676.94,-2196.59)
 .. controls (-675.68,-2192.27) and (-670.98,-2177.07) .. (-666.01,-2169.33)
 .. controls (-661.01,-2161.54) and (-650.92,-2142.57) .. (-647.94,-2137.73)
 .. controls (-644.97,-2132.90) and (-629.07,-2103.25) .. (-627.79,-2100.33)
 .. controls (-626.50,-2097.42) and (-621.15,-2070.78) .. (-615.30,-2050.56)
 .. controls (-609.50,-2030.48) and (-616.15,-2008.59) .. (-617.07,-2006.28)
 .. controls (-617.99,-2003.97) and (-619.57,-1988.89) .. (-619.24,-1985.70)
 .. controls (-618.91,-1982.51) and (-612.59,-1969.81) .. (-611.21,-1965.58)
 .. controls (-609.82,-1961.35) and (-601.59,-1948.74) .. (-597.00,-1944.58)
));
ATTR__id := "l259-2880-6384";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-784.78,-2051.57)
 .. controls (-782.11,-2049.49) and (-776.59,-2047.64) .. (-770.39,-2047.62)
 .. controls (-764.37,-2047.60) and (-765.31,-2049.44) .. (-757.03,-2047.86)
 .. controls (-748.81,-2046.30) and (-751.59,-2049.48) .. (-750.48,-2052.40)
 .. controls (-749.36,-2055.35) and (-750.70,-2061.51) .. (-750.93,-2067.04)
 .. controls (-751.15,-2072.72) and (-753.83,-2091.35) .. (-754.27,-2094.49)
 .. controls (-754.71,-2097.64) and (-763.06,-2145.64) .. (-765.11,-2157.38)
 .. controls (-767.11,-2168.82) and (-765.59,-2196.14) .. (-764.51,-2200.64)
));
ATTR__id := "";
drawoptions();
p_waterflow_permanent((-400.04,-1679.86),309.5,1.00,(0,0));
drawoptions();
p_waterflow_permanent((-356.84,-1642.77),309.5,1.00,(0,0));
drawoptions();
p_stalagmite((-306.14,-1497.06),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((-275.91,-1497.08),0.0,1.00,(0,0));
drawoptions();
p_stalactite((-291.74,-1483.02),0.0,1.00,(0,0));
ATTR__id := "l107-2658-7064";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-725.57,-1941.40)
 .. controls (-727.74,-1948.26) and (-744.88,-1958.52) .. (-750.06,-1958.79)
 .. controls (-755.22,-1959.06) and (-774.12,-1958.31) .. (-778.73,-1960.18)
 .. controls (-783.33,-1962.05) and (-795.04,-1983.81) .. (-798.09,-1988.10)
 .. controls (-801.16,-1992.41) and (-806.46,-1998.75) .. (-809.82,-2001.52)
 .. controls (-813.21,-2004.32) and (-826.51,-2014.69) .. (-828.52,-2015.66)
));
ATTR__id := "l54-5320-8936";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-597.00,-1944.58)
 .. controls (-594.89,-1941.95) and (-590.31,-1936.00) .. (-585.51,-1932.67)
 .. controls (-580.69,-1929.33) and (-572.62,-1926.66) .. (-567.93,-1925.92)
 .. controls (-563.23,-1925.18) and (-543.52,-1917.47) .. (-540.28,-1915.67)
 .. controls (-537.04,-1913.87) and (-519.29,-1903.54) .. (-514.81,-1899.25)
 .. controls (-510.32,-1894.95) and (-502.22,-1875.86) .. (-499.68,-1868.81)
 .. controls (-497.14,-1861.77) and (-491.75,-1846.48) .. (-490.68,-1841.10)
 .. controls (-489.62,-1835.73) and (-488.39,-1822.28) .. (-487.49,-1817.42)
 .. controls (-486.59,-1812.56) and (-482.98,-1803.54) .. (-480.27,-1798.31)
 .. controls (-477.57,-1793.08) and (-469.08,-1783.13) .. (-462.40,-1777.70)
 .. controls (-455.72,-1772.27) and (-441.83,-1763.22) .. (-438.04,-1761.06)
 .. controls (-434.26,-1758.89) and (-425.43,-1750.59) .. (-422.72,-1746.81)
 .. controls (-420.02,-1743.03) and (-410.12,-1730.42) .. (-406.51,-1727.72)
 .. controls (-402.91,-1725.01) and (-390.48,-1710.23) .. (-386.69,-1707.53)
 .. controls (-382.91,-1704.82) and (-367.60,-1691.31) .. (-359.68,-1682.67)
 .. controls (-351.77,-1674.04) and (-341.34,-1665.06) .. (-335.04,-1662.37)
 .. controls (-328.75,-1659.68) and (-308.09,-1646.05) .. (-304.13,-1642.46)
 .. controls (-300.18,-1638.88) and (-272.67,-1617.86) .. (-266.37,-1612.64)
 .. controls (-260.07,-1607.42) and (-240.99,-1592.66) .. (-234.69,-1587.81)
 .. controls (-228.40,-1582.95) and (-191.93,-1545.98) .. (-187.61,-1542.02)
 .. controls (-183.29,-1538.07) and (-177.53,-1520.25) .. (-174.65,-1512.14)
 .. controls (-171.76,-1504.03) and (-157.69,-1480.59) .. (-155.71,-1476.45)
 .. controls (-153.73,-1472.30) and (-131.95,-1430.55) .. (-128.71,-1425.51)
 .. controls (-125.47,-1420.47) and (-116.29,-1409.14) .. (-113.77,-1405.18)
 .. controls (-111.25,-1401.22) and (-90.93,-1371.01) .. (-89.49,-1364.36)
 .. controls (-88.06,-1357.71) and (-79.42,-1340.62) .. (-77.80,-1335.57)
));
ATTR__id := "l96-3588-7456";
ATTR__height := -1;
drawoptions();
l_wall_flowstone(((-512.58,-1755.52)
 .. controls (-509.71,-1754.80) and (-506.13,-1763.12) .. (-505.97,-1767.46)
 .. controls (-505.80,-1771.80) and (-507.27,-1784.99) .. (-506.74,-1788.06)
 .. controls (-506.21,-1791.13) and (-500.27,-1803.92) .. (-499.19,-1808.23)
 .. controls (-498.11,-1812.55) and (-509.23,-1829.06) .. (-512.28,-1834.25)
 .. controls (-515.32,-1839.45) and (-528.27,-1855.09) .. (-532.60,-1862.12)
 .. controls (-536.92,-1869.14) and (-548.58,-1875.91) .. (-556.29,-1880.92)
 .. controls (-564.03,-1885.94) and (-571.63,-1896.28) .. (-575.61,-1899.91)
 .. controls (-579.59,-1903.54) and (-594.66,-1912.65) .. (-599.47,-1914.73)
 .. controls (-604.27,-1916.80) and (-630.55,-1921.17) .. (-646.54,-1925.79)
 .. controls (-662.68,-1930.45) and (-662.82,-1925.80) .. (-665.67,-1923.96)
 .. controls (-668.52,-1922.11) and (-671.33,-1913.91) .. (-672.21,-1910.63)
));
ATTR__id := "l52-4360-9108";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-206.45,-1279.69)
 .. controls (-208.25,-1286.16) and (-215.81,-1309.37) .. (-215.81,-1315.14)
 .. controls (-215.81,-1320.90) and (-222.30,-1354.93) .. (-224.46,-1361.05)
 .. controls (-226.63,-1367.18) and (-231.67,-1374.38) .. (-233.83,-1379.60)
 .. controls (-235.99,-1384.81) and (-250.73,-1417.37) .. (-253.25,-1424.20)
 .. controls (-255.76,-1431.04) and (-266.73,-1457.66) .. (-268.89,-1461.08)
 .. controls (-271.05,-1464.49) and (-287.24,-1470.96) .. (-297.85,-1473.65)
 .. controls (-308.46,-1476.34) and (-336.52,-1484.95) .. (-344.80,-1487.28)
 .. controls (-353.07,-1489.61) and (-395.51,-1512.40) .. (-403.96,-1519.05)
 .. controls (-412.41,-1525.69) and (-442.43,-1552.82) .. (-447.11,-1559.65)
 .. controls (-451.79,-1566.49) and (-485.81,-1602.32) .. (-489.61,-1612.24)
 .. controls (-493.41,-1622.17) and (-503.86,-1636.77) .. (-507.11,-1641.82)
 .. controls (-510.35,-1646.86) and (-523.65,-1658.71) .. (-527.79,-1670.77)
 .. controls (-531.92,-1682.82) and (-547.53,-1710.11) .. (-553.81,-1716.74)
 .. controls (-560.09,-1723.37) and (-573.72,-1725.62) .. (-578.20,-1726.13)
 .. controls (-582.68,-1726.64) and (-596.83,-1730.32) .. (-610.45,-1746.41)
 .. controls (-624.04,-1762.48) and (-631.37,-1770.50) .. (-636.19,-1777.64)
 .. controls (-641.01,-1784.78) and (-646.55,-1786.87) .. (-658.85,-1804.68)
 .. controls (-671.13,-1822.46) and (-677.71,-1829.53) .. (-679.65,-1839.01)
 .. controls (-681.59,-1848.48) and (-692.23,-1872.52) .. (-695.60,-1879.47)
 .. controls (-698.98,-1886.42) and (-706.63,-1898.35) .. (-711.63,-1905.83)
 .. controls (-716.63,-1913.33) and (-720.22,-1921.24) .. (-722.06,-1927.95)
 .. controls (-723.90,-1934.67) and (-725.76,-1942.68) .. (-725.76,-1942.68)
));
ATTR__id := "l94-4212-8378";
ATTR__height := -1;
drawoptions();
l_wall_flowstone(((-672.21,-1910.63)
 .. controls (-672.21,-1910.63) and (-672.34,-1899.41) .. (-672.51,-1893.45)
 .. controls (-672.68,-1887.50) and (-673.03,-1872.55) .. (-670.72,-1863.06)
 .. controls (-668.42,-1853.57) and (-660.96,-1835.91) .. (-660.43,-1830.71)
 .. controls (-659.90,-1825.50) and (-634.40,-1792.59) .. (-631.01,-1786.70)
 .. controls (-627.61,-1780.80) and (-607.76,-1761.38) .. (-600.43,-1754.07)
 .. controls (-593.08,-1746.74) and (-577.86,-1748.49) .. (-570.51,-1747.64)
 .. controls (-563.17,-1746.79) and (-546.68,-1753.20) .. (-540.05,-1757.57)
 .. controls (-533.43,-1761.94) and (-530.91,-1760.15) .. (-524.26,-1757.47)
 .. controls (-517.61,-1754.78) and (-512.58,-1755.52) .. (-512.58,-1755.52)
));
ATTR__id := "";
drawoptions();
p_sodastraw((263.30,-390.95),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((342.86,-282.96),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((338.90,-343.07),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((422.06,-190.42),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((472.46,-11.52),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((439.34,65.89),0.0,1.00,(0,0));
drawoptions();
p_stalactite((308.66,-323.63),0.0,1.00,(0,0));
drawoptions();
p_stalactite((385.34,-284.76),0.0,1.00,(0,0));
drawoptions();
p_stalactite((371.30,-240.48),0.0,1.00,(0,0));
drawoptions();
p_stalactite((435.02,-154.07),0.0,1.00,(0,0));
drawoptions();
p_sodastraw((463.10,-121.32),0.0,1.00,(0,0));
ATTR__id := "l30-9984-17468";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-77.80,-1335.57)
 .. controls (-73.66,-1326.93) and (-80.85,-1310.36) .. (-72.93,-1290.19)
 .. controls (-65.01,-1270.03) and (-54.93,-1252.02) .. (-58.53,-1230.43)
 .. controls (-62.13,-1208.83) and (-65.02,-1182.20) .. (-68.62,-1171.41)
 .. controls (-72.23,-1160.62) and (-71.50,-1138.29) .. (-70.78,-1125.33)
 .. controls (-70.05,-1112.36) and (-71.48,-1088.60) .. (-59.96,-1071.32)
 .. controls (-48.44,-1054.04) and (-34.76,-1019.48) .. (-14.60,-1003.64)
 .. controls (5.56,-987.79) and (46.59,-945.33) .. (53.79,-932.37)
 .. controls (60.99,-919.40) and (97.72,-886.27) .. (103.48,-873.31)
 .. controls (109.24,-860.36) and (132.28,-816.44) .. (135.88,-804.93)
 .. controls (139.47,-793.41) and (145.94,-724.30) .. (187.71,-693.33)
 .. controls (229.47,-662.38) and (229.47,-624.94) .. (235.23,-614.86)
 .. controls (240.99,-604.78) and (243.87,-552.23) .. (243.87,-547.91)
 .. controls (243.87,-543.59) and (246.03,-519.83) .. (254.67,-504.71)
 .. controls (263.31,-489.59) and (278.42,-468.71) .. (285.62,-457.91)
 .. controls (292.82,-447.11) and (309.38,-415.43) .. (315.14,-408.95)
 .. controls (320.90,-402.47) and (347.54,-384.47) .. (356.18,-374.39)
 .. controls (364.82,-364.31) and (438.26,-284.39) .. (444.74,-272.15)
 .. controls (451.21,-259.90) and (456.97,-236.86) .. (461.29,-225.34)
 .. controls (465.61,-213.82) and (477.13,-203.75) .. (483.61,-194.39)
 .. controls (490.09,-185.04) and (510.97,-159.13) .. (510.97,-148.33)
 .. controls (510.97,-137.53) and (519.61,-108.02) .. (529.69,-91.47)
 .. controls (539.77,-74.91) and (544.10,-36.03) .. (544.10,-30.27)
 .. controls (544.10,-24.51) and (549.86,23.73) .. (547.70,35.97)
 .. controls (545.54,48.21) and (537.62,71.26) .. (546.26,90.69)
 .. controls (554.90,110.13) and (570.02,138.93) .. (576.50,150.45)
 .. controls (582.98,161.96) and (598.81,189.31) .. (597.37,201.55)
 .. controls (595.93,213.79) and (593.95,235.92) .. (568.03,243.14)
 .. controls (542.12,250.36) and (505.94,254.15) .. (493.70,253.43)
 .. controls (481.46,252.71) and (452.67,247.68) .. (437.55,266.41)
 .. controls (422.43,285.13) and (419.54,281.53) .. (417.38,287.29)
));
ATTR__id := "l29-9392-18376";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((408.75,252.73)
 .. controls (420.27,255.62) and (418.83,258.50) .. (428.91,243.37)
 .. controls (438.98,228.24) and (432.50,200.15) .. (429.62,187.19)
 .. controls (426.74,174.23) and (417.37,146.15) .. (420.26,135.35)
 .. controls (423.14,124.55) and (417.38,89.27) .. (414.50,72.00)
 .. controls (411.62,54.72) and (407.30,15.84) .. (408.02,0.72)
 .. controls (408.74,-14.40) and (408.74,-64.08) .. (405.14,-80.63)
 .. controls (401.54,-97.18) and (399.38,-109.42) .. (399.38,-128.15)
 .. controls (399.38,-146.87) and (389.30,-187.91) .. (375.62,-200.87)
 .. controls (361.94,-213.84) and (332.42,-257.77) .. (325.22,-272.16)
 .. controls (318.02,-286.56) and (287.06,-327.59) .. (282.02,-334.07)
 .. controls (276.98,-340.55) and (253.22,-362.87) .. (246.02,-380.15)
 .. controls (238.82,-397.43) and (234.50,-424.79) .. (227.30,-441.35)
 .. controls (220.11,-457.91) and (200.67,-509.03) .. (197.07,-519.83)
 .. controls (193.47,-530.63) and (174.02,-596.86) .. (170.42,-603.34)
 .. controls (166.82,-609.82) and (140.91,-649.42) .. (127.95,-658.06)
 .. controls (114.99,-666.70) and (74.68,-702.69) .. (67.48,-719.25)
 .. controls (60.28,-735.81) and (21.38,-799.17) .. (19.23,-817.17)
 .. controls (17.07,-835.17) and (3.40,-861.80) .. (-3.08,-868.28)
 .. controls (-9.56,-874.76) and (-36.92,-901.39) .. (-44.12,-915.08)
 .. controls (-51.32,-928.76) and (-79.41,-974.12) .. (-79.41,-984.20)
 .. controls (-79.41,-994.29) and (-109.64,-1038.92) .. (-116.85,-1056.20)
 .. controls (-124.05,-1073.49) and (-151.40,-1131.07) .. (-157.16,-1147.62)
 .. controls (-162.92,-1164.17) and (-186.67,-1227.52) .. (-191.70,-1242.63)
 .. controls (-196.74,-1257.74) and (-206.45,-1279.69) .. (-206.45,-1279.69)
));
ATTR__id := "l6-11026-27178";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((579.00,1358.63)
 .. controls (579.00,1358.63) and (577.83,1360.50) .. (576.33,1374.57)
 .. controls (575.42,1383.13) and (580.44,1391.03) .. (583.99,1397.93)
 .. controls (587.58,1404.89) and (604.52,1430.29) .. (610.78,1442.85)
 .. controls (616.97,1455.31) and (635.29,1485.00) .. (640.49,1489.33)
 .. controls (645.69,1493.68) and (660.77,1518.68) .. (663.45,1524.28)
 .. controls (666.13,1529.88) and (671.77,1555.70) .. (677.55,1571.37)
 .. controls (683.21,1586.68) and (695.94,1611.23) .. (699.51,1615.09)
 .. controls (703.08,1618.95) and (708.99,1635.90) .. (715.12,1649.14)
 .. controls (721.31,1662.47) and (722.27,1679.11) .. (723.36,1686.37)
 .. controls (724.45,1693.60) and (722.09,1710.46) .. (724.41,1718.83)
 .. controls (726.72,1727.19) and (719.28,1759.71) .. (718.38,1765.10)
 .. controls (717.48,1770.50) and (711.92,1788.93) .. (711.22,1803.59)
 .. controls (710.52,1818.24) and (705.51,1842.27) .. (703.89,1844.26)
 .. controls (702.27,1846.25) and (698.31,1860.65) .. (698.31,1863.89)
 .. controls (698.31,1867.12) and (697.95,1884.05) .. (696.16,1889.10)
 .. controls (694.36,1894.16) and (693.31,1909.35) .. (692.06,1918.39)
 .. controls (690.81,1927.42) and (693.33,1936.06) .. (694.22,1941.63)
 .. controls (695.12,1947.20) and (694.39,1968.58) .. (696.00,1976.32)
 .. controls (697.63,1984.06) and (697.45,1993.98) .. (699.25,2002.45)
 .. controls (701.05,2010.92) and (707.89,2013.46) .. (717.44,2017.61)
 .. controls (726.98,2021.76) and (737.95,2043.50) .. (740.47,2049.24)
 .. controls (742.99,2054.99) and (756.47,2083.57) .. (757.38,2088.97)
 .. controls (758.28,2094.37) and (775.21,2135.47) .. (778.10,2141.79)
 .. controls (780.98,2148.10) and (789.81,2159.46) .. (791.07,2164.68)
));
ATTR__id := "l29-3238-5890";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-767.75,-2196.14)
 .. controls (-766.31,-2198.84) and (-761.63,-2202.61) .. (-759.27,-2204.02)
 .. controls (-756.91,-2205.43) and (-752.54,-2207.33) .. (-750.17,-2207.11)
 .. controls (-747.81,-2206.89) and (-746.53,-2207.76) .. (-741.07,-2204.60)
 .. controls (-735.61,-2201.44) and (-727.08,-2200.24) .. (-725.62,-2196.62)
 .. controls (-724.16,-2192.98) and (-721.90,-2193.48) .. (-720.92,-2192.98)
 .. controls (-719.48,-2192.26) and (-716.53,-2192.64) .. (-714.48,-2194.49)
 .. controls (-713.06,-2195.78) and (-710.09,-2198.70) .. (-709.15,-2200.54)
 .. controls (-707.19,-2204.36) and (-706.30,-2206.17) .. (-702.20,-2206.24)
 .. controls (-698.11,-2206.31) and (-695.08,-2204.22) .. (-691.17,-2202.31)
 .. controls (-687.25,-2200.39) and (-684.39,-2199.35) .. (-681.88,-2198.10)
 .. controls (-679.37,-2196.86) and (-673.79,-2195.24) .. (-673.79,-2195.24)
));
ATTR__id := "";
drawoptions();
p_stalagmite((646.47,1614.48),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((664.84,1644.41),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((680.00,1659.32),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((592.64,898.02),0.0,1.00,(0,0));
drawoptions();
p_stalagmites((523.62,1524.28),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((500.81,1515.34),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((482.54,1522.87),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((496.82,1539.88),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((538.45,1531.20),0.0,1.00,(0,0));
drawoptions();
p_stalactites((512.26,1556.13),0.0,1.00,(0,0));
ATTR__id := "l5-9716-25416";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((417.38,287.29)
 .. controls (417.38,287.29) and (411.62,294.66) .. (413.60,307.26)
 .. controls (415.58,319.85) and (423.31,337.47) .. (421.51,345.20)
 .. controls (419.71,352.94) and (417.18,361.21) .. (418.98,370.57)
 .. controls (420.78,379.93) and (425.10,398.65) .. (425.46,402.08)
 .. controls (425.82,405.50) and (424.38,424.95) .. (435.90,432.48)
 .. controls (447.41,440.02) and (462.52,458.88) .. (463.42,460.68)
 .. controls (464.32,462.48) and (487.00,488.55) .. (492.58,494.49)
 .. controls (498.16,500.43) and (519.05,527.83) .. (521.21,532.35)
 .. controls (523.38,536.86) and (547.15,579.92) .. (548.95,585.67)
 .. controls (550.75,591.43) and (555.23,608.85) .. (555.58,630.94)
 .. controls (555.93,653.06) and (554.31,673.06) .. (554.50,685.32)
 .. controls (554.68,697.58) and (554.86,716.13) .. (556.84,726.37)
 .. controls (558.81,736.61) and (570.14,775.61) .. (572.48,782.28)
 .. controls (574.83,788.96) and (583.13,812.82) .. (584.76,818.79)
 .. controls (586.38,824.74) and (586.75,833.58) .. (588.01,841.14)
 .. controls (589.26,848.68) and (594.29,855.84) .. (603.63,864.77)
 .. controls (612.97,873.69) and (632.55,900.36) .. (635.25,905.92)
 .. controls (637.94,911.47) and (656.80,953.43) .. (658.60,963.86)
 .. controls (660.40,974.31) and (666.39,1018.23) .. (664.96,1032.17)
 .. controls (663.54,1046.06) and (653.41,1078.08) .. (632.08,1095.26)
 .. controls (610.77,1112.41) and (555.36,1152.27) .. (550.88,1154.67)
 .. controls (546.40,1157.07) and (525.37,1173.54) .. (496.88,1160.31)
 .. controls (468.34,1147.07) and (447.30,1136.79) .. (444.06,1134.48)
 .. controls (440.83,1132.16) and (412.99,1114.81) .. (411.48,1155.18)
 .. controls (409.98,1195.67) and (408.01,1202.53) .. (409.98,1208.45)
 .. controls (411.96,1214.39) and (410.50,1224.63) .. (425.65,1234.95)
 .. controls (440.66,1245.17) and (456.55,1255.39) .. (457.61,1260.52)
 .. controls (458.66,1265.63) and (468.30,1310.70) .. (469.96,1318.67)
 .. controls (471.63,1326.65) and (473.57,1359.46) .. (474.27,1369.36)
 .. controls (474.99,1379.46) and (477.90,1416.44) .. (480.12,1421.00)
 .. controls (482.34,1425.53) and (483.74,1447.15) .. (502.35,1437.73)
 .. controls (522.23,1427.66) and (527.56,1425.82) .. (530.00,1423.56)
 .. controls (532.42,1421.31) and (541.86,1410.44) .. (542.93,1406.76)
 .. controls (543.99,1403.11) and (545.25,1401.85) .. (549.15,1399.20)
 .. controls (553.05,1396.56) and (558.10,1396.38) .. (559.76,1392.86)
 .. controls (561.40,1389.39) and (563.13,1387.56) .. (561.41,1381.75)
 .. controls (559.21,1374.31) and (559.26,1373.28) .. (555.48,1368.71)
));
ATTR__id := "";
drawoptions();
p_stalagmite((427.92,1115.81),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((560.98,909.29),0.0,1.00,(0,0));
drawoptions();
p_stalagmite((636.85,938.43),0.0,1.00,(0,0));
drawoptions();
p_stalactite((648.36,984.84),0.0,1.00,(0,0));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((711.51,2186.46)
 .. controls (709.89,2181.24) and (707.18,2168.09) .. (706.64,2158.00)
 .. controls (706.10,2147.90) and (701.58,2121.39) .. (698.88,2115.98)
 .. controls (696.18,2110.58) and (683.57,2077.10) .. (682.32,2069.37)
 .. controls (681.06,2061.64) and (676.92,2049.96) .. (677.11,2046.73)
 .. controls (677.29,2043.50) and (676.57,2034.70) .. (668.30,2026.25)
 .. controls (660.01,2017.78) and (646.50,2000.80) .. (641.27,1978.06)
 .. controls (636.04,1955.35) and (629.56,1943.63) .. (631.90,1937.33)
 .. controls (634.24,1931.04) and (632.08,1931.21) .. (634.96,1929.78)
 .. controls (637.84,1928.35) and (638.38,1927.09) .. (639.64,1920.79)
 .. controls (640.90,1914.48) and (647.20,1899.71) .. (647.74,1892.68)
 .. controls (648.27,1885.66) and (652.78,1874.35) .. (652.07,1864.31)
 .. controls (651.36,1854.28) and (653.17,1851.60) .. (654.61,1849.09)
 .. controls (656.06,1846.59) and (655.88,1840.66) .. (655.70,1834.72)
 .. controls (655.52,1828.77) and (657.14,1828.78) .. (657.68,1827.16)
 .. controls (658.22,1825.53) and (660.37,1820.29) .. (661.44,1816.12)
 .. controls (662.51,1811.95) and (666.05,1788.86) .. (668.92,1785.04)
 .. controls (671.79,1781.22) and (678.05,1755.17) .. (679.13,1748.69)
 .. controls (680.21,1742.23) and (680.24,1717.50) .. (681.33,1715.18)
 .. controls (682.41,1712.87) and (685.13,1705.73) .. (684.05,1702.48)
 .. controls (682.97,1699.23) and (676.81,1684.69) .. (673.91,1681.75)
 .. controls (671.02,1678.81) and (656.91,1660.02) .. (653.84,1654.22)
 .. controls (650.78,1648.43) and (637.79,1632.29) .. (633.46,1628.26)
 .. controls (629.11,1624.22) and (610.14,1617.80) .. (601.30,1615.60)
 .. controls (592.48,1613.41) and (571.29,1606.87) .. (567.71,1603.88)
 .. controls (564.13,1600.90) and (516.91,1579.89) .. (512.08,1573.73)
 .. controls (507.24,1567.59) and (470.67,1526.49) .. (466.69,1516.93)
 .. controls (462.78,1507.53) and (451.44,1483.25) .. (449.74,1478.00)
 .. controls (448.02,1472.72) and (448.43,1468.93) .. (446.30,1466.68)
 .. controls (444.15,1464.41) and (439.08,1463.28) .. (435.30,1457.98)
 .. controls (431.45,1452.58) and (420.21,1424.77) .. (418.34,1420.57)
 .. controls (416.47,1416.38) and (406.65,1383.92) .. (404.67,1376.52)
 .. controls (402.70,1369.20) and (396.52,1337.40) .. (394.63,1331.22)
 .. controls (392.74,1325.05) and (388.50,1304.36) .. (385.66,1299.08)
 .. controls (382.80,1293.75) and (364.18,1267.52) .. (360.74,1261.88)
 .. controls (357.31,1256.25) and (345.96,1246.14) .. (340.03,1241.33)
 .. controls (334.12,1236.53) and (281.65,1188.27) .. (272.81,1180.80)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((284.65,1087.36)
 .. controls (325.73,1080.33) and (357.81,1074.40) .. (362.51,1070.32)
 .. controls (367.21,1066.25) and (377.88,1058.68) .. (382.40,1052.64)
 .. controls (386.92,1046.59) and (397.56,1033.70) .. (400.08,1031.53)
 .. controls (402.60,1029.37) and (405.66,1028.84) .. (410.34,1028.48)
 .. controls (415.02,1028.11) and (419.69,1026.64) .. (421.66,1025.35)
 .. controls (423.64,1024.07) and (437.98,1013.44) .. (443.90,1001.80)
 .. controls (449.81,990.19) and (461.50,982.94) .. (464.56,979.33)
 .. controls (467.62,975.73) and (475.72,968.36) .. (476.27,966.03)
 .. controls (476.81,963.69) and (482.03,958.68) .. (487.25,962.64)
 .. controls (492.47,966.61) and (507.96,974.38) .. (510.65,977.08)
 .. controls (513.35,979.78) and (524.32,992.87) .. (525.04,997.88)
 .. controls (525.75,1002.89) and (535.63,1021.17) .. (537.61,1023.51)
 .. controls (539.59,1025.84) and (541.38,1032.66) .. (544.26,1033.92)
 .. controls (547.14,1035.19) and (564.61,1041.02) .. (565.16,1027.02)
 .. controls (565.72,1013.03) and (563.56,1003.71) .. (563.39,999.77)
 .. controls (563.22,995.84) and (563.98,976.74) .. (564.18,970.32)
 .. controls (564.37,963.90) and (564.05,951.23) .. (563.33,946.05)
 .. controls (562.62,940.85) and (561.36,929.35) .. (558.48,923.39)
 .. controls (555.59,917.42) and (549.27,904.38) .. (545.12,898.94)
 .. controls (540.98,893.51) and (534.31,889.52) .. (531.24,885.91)
 .. controls (528.18,882.30) and (526.56,879.05) .. (524.22,872.74)
 .. controls (521.88,866.44) and (521.88,849.54) .. (519.72,842.33)
 .. controls (517.56,835.13) and (513.06,821.62) .. (507.11,811.89)
 .. controls (501.17,802.16) and (486.96,777.00) .. (482.65,769.99)
 .. controls (478.33,762.99) and (468.97,748.60) .. (467.90,744.65)
 .. controls (466.82,740.69) and (455.29,730.40) .. (454.93,720.69)
 .. controls (454.58,710.98) and (452.41,688.83) .. (450.97,684.32)
 .. controls (449.53,679.82) and (443.96,646.33) .. (443.06,639.49)
 .. controls (442.16,632.66) and (436.05,605.13) .. (425.78,595.40)
 .. controls (415.52,585.67) and (397.34,561.38) .. (393.02,555.80)
 .. controls (388.70,550.22) and (365.13,531.70) .. (359.73,519.66)
 .. controls (354.34,507.63) and (345.88,488.58) .. (342.29,481.21)
 .. controls (338.69,473.84) and (325.37,458.54) .. (323.75,450.62)
 .. controls (322.13,442.71) and (318.53,422.19) .. (318.17,415.53)
 .. controls (317.81,408.87) and (317.46,388.35) .. (310.80,374.67)
 .. controls (304.14,360.99) and (302.34,339.76) .. (301.80,332.38)
 .. controls (301.26,325.00) and (303.61,294.78) .. (304.69,292.08)
 .. controls (305.77,289.38) and (306.31,292.62) .. (309.73,287.23)
 .. controls (313.15,281.83) and (315.68,271.21) .. (313.88,265.63)
 .. controls (312.07,260.05) and (307.76,238.62) .. (309.38,233.58)
 .. controls (311.00,228.54) and (314.06,211.08) .. (316.22,206.94)
 .. controls (318.38,202.80) and (318.02,184.80) .. (328.28,183.73)
 .. controls (338.54,182.65) and (346.46,185.18) .. (353.84,196.52)
 .. controls (361.22,207.87) and (368.78,214.71) .. (372.74,220.30)
 .. controls (376.70,225.88) and (384.98,237.41) .. (388.40,239.75)
 .. controls (391.82,242.10) and (391.82,247.14) .. (396.86,248.58)
 .. controls (401.91,250.02) and (405.87,252.37) .. (408.75,252.73)
));
endfig;
beginfig(16);
drawoptions();
p_label(btex \thlabel\thnormalsize \thfb\char67 \char111 \char110 \char115 \char112 \char105 \char114 \char97 \char99 \char121 \ \char68 \char117 \char99 \char107 \mainfont{} etex,(516.01,292.99),0.0,0);
endfig;
background:=(1.00000,0.25000,0.25000);
def_transparent_rgb(tr_bg, 1.00000, 0.25000, 0.25000);
current_scrap := "romeoSP0@romeo_entrance.romeo";
ATTR__scrap := "romeoSP0";
beginfig(17);
current_src := "Romeo_entrance.th2 [3889]";
string area_border[];
area_border[1] := "l2-3472-6720";
drawoptions();
a_water(buildcycle(((-196.15,142.60)
 .. controls (-198.13,143.32) and (-199.75,142.60) .. (-202.99,143.14)
 .. controls (-206.23,143.68) and (-212.17,143.68) .. (-217.21,143.86)
 .. controls (-222.25,144.04) and (-226.03,142.42) .. (-233.23,140.26)
 .. controls (-240.43,138.10) and (-237.73,135.22) .. (-244.57,125.50)
 .. controls (-251.41,115.78) and (-242.41,101.92) .. (-247.99,89.32)
 .. controls (-253.57,76.72) and (-248.35,75.99) .. (-251.06,63.57)
 .. controls (-253.76,51.15) and (-252.32,44.67) .. (-251.42,31.35)
 .. controls (-250.52,18.03) and (-249.62,17.13) .. (-249.62,5.43)
 .. controls (-249.62,-6.27) and (-249.62,1.83) .. (-247.64,-4.65)
 .. controls (-245.66,-11.13) and (-244.40,-6.63) .. (-241.16,-7.53)
 .. controls (-237.92,-8.43) and (-233.97,-8.97) .. (-231.81,-8.61)
 .. controls (-229.65,-8.25) and (-224.25,-5.73) .. (-219.03,-4.11)
 .. controls (-213.81,-2.49) and (-213.80,0.57) .. (-210.02,7.05)
 .. controls (-206.24,13.53) and (-205.88,23.97) .. (-201.20,30.28)
 .. controls (-196.52,36.58) and (-194.35,47.02) .. (-192.01,52.42)
 .. controls (-189.67,57.82) and (-184.45,62.68) .. (-179.77,68.98)
 .. controls (-175.09,75.28) and (-173.47,83.20) .. (-171.49,89.14)
 .. controls (-169.51,95.08) and (-168.25,96.52) .. (-171.13,99.22)
 .. controls (-174.01,101.92) and (-176.71,97.60) .. (-181.21,99.22)
 .. controls (-185.71,100.84) and (-180.85,101.56) .. (-181.39,112.36)
 .. controls (-181.93,123.16) and (-177.79,126.76) .. (-179.23,133.78)
 .. controls (-180.67,140.80) and (-194.17,141.88) .. cycle
)));
current_src := "Romeo_entrance.th2 [3790]";
string area_border[];
area_border[1] := "l86-5372-7218";
area_border[2] := "l217-5828-7294";
area_border[3] := "l87-5698-7070";
area_border[4] := "l218-5044-6636";
drawoptions();
a_blocks(buildcycle(((280.32,318.83)
 .. controls (276.18,313.97) and (272.94,311.09) .. (266.82,307.31)
 .. controls (260.70,303.53) and (258.72,305.15) .. (253.50,304.07)
 .. controls (248.28,302.99) and (241.08,298.85) .. (237.30,293.63)
 .. controls (233.52,288.41) and (226.49,284.81) .. (225.05,279.95)
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
 .. controls (-25.32,41.26) and (-47.10,24.52) .. (-49.44,19.84)
 .. controls (-51.78,15.16) and (-66.90,-4.82) .. (-69.96,-9.86)
 .. controls (-73.02,-14.90) and (-76.98,-23.90) .. (-86.16,-26.60)
 .. controls (-95.34,-29.30) and (-104.16,-26.42) .. (-112.44,-33.44)
 .. controls (-120.72,-40.46) and (-126.84,-45.86) .. (-128.28,-47.84)
 .. controls (-129.72,-49.82) and (-136.20,-50.72) .. (-138.18,-51.08)
 .. controls (-140.16,-51.44) and (-143.40,-54.14) .. (-144.84,-59.54)
 .. controls (-146.28,-64.94) and (-150.24,-75.02) .. (-154.92,-79.52)
 .. controls (-159.60,-84.02) and (-159.96,-90.86) .. (-164.82,-94.46)
 .. controls (-169.68,-98.06) and (-175.63,-101.66) .. (-176.71,-104.90)
 .. controls (-177.79,-108.14) and (-179.95,-118.58) .. (-181.93,-120.92)
 .. controls (-183.91,-123.26) and (-196.15,-131.72) .. (-199.03,-133.52)
 .. controls (-201.91,-135.32) and (-211.09,-147.38) .. (-214.15,-148.10)
 .. controls (-217.22,-148.82) and (-221.90,-147.38) .. (-227.48,-152.96)
 .. controls (-233.06,-158.54) and (-235.94,-161.96) .. (-239.36,-164.30)
 .. controls (-242.78,-166.64) and (-248.90,-170.78) .. (-251.60,-171.50)
 .. controls (-254.30,-172.22) and (-257.71,-176.18) .. (-260.60,-176.18)
 .. controls (-263.48,-176.18) and (-266.00,-177.44) .. (-269.78,-177.44)
),
((213.17,272.39)
 .. controls (213.17,272.39) and (236.57,245.39) .. (241.61,239.63)
 .. controls (246.65,233.86) and (243.77,204.34) .. (245.21,193.90)
),
((-460.06,-315.14)
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
 .. controls (-11.46,-8.59) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.66,39.29) .. (23.82,40.73)
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
 .. controls (299.75,218.92) and (310.74,234.04) .. (310.38,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
),
((32.45,106.79)
 .. controls (32.45,106.79) and (56.21,88.79) .. (62.69,96.35)
 .. controls (69.17,103.91) and (87.89,122.27) .. (95.09,116.87)
 .. controls (102.29,111.47) and (118.13,101.75) .. (123.17,105.71)
)));
current_src := "Romeo_entrance.th2 [3784]";
string area_border[];
area_border[1] := "l234-2647-4824";
area_border[2] := "l235-2856-4769";
area_border[3] := "l227-2946-4718";
drawoptions();
a_blocks(buildcycle(((-290.66,-210.92)
 .. controls (-293.36,-211.82) and (-295.34,-212.36) .. (-300.92,-212.90)
 .. controls (-306.50,-213.44) and (-307.76,-214.16) .. (-314.06,-214.70)
 .. controls (-320.36,-215.24) and (-324.50,-214.88) .. (-329.90,-216.32)
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
current_src := "Romeo_entrance.th2 [3777]";
string area_border[];
area_border[1] := "l238-2596-4325";
area_border[2] := "l87-5698-7070";
area_border[3] := "l235-2856-4769";
area_border[4] := "l234-2647-4824";
drawoptions();
a_pebbles(buildcycle(((-341.61,-294.44)
 .. controls (-340.53,-295.34) and (-333.87,-311.72) .. (-331.71,-315.86)
 .. controls (-329.55,-320.00) and (-317.67,-325.76) .. (-317.67,-325.76)
),
((-460.06,-315.14)
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
 .. controls (-11.46,-8.59) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.66,39.29) .. (23.82,40.73)
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
 .. controls (299.75,218.92) and (310.74,234.04) .. (310.38,242.32)
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
 .. controls (-320.36,-215.24) and (-324.50,-214.88) .. (-329.90,-216.32)
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
current_src := "Romeo_entrance.th2 [3770]";
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
((-460.06,-315.14)
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
 .. controls (-11.46,-8.59) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.66,39.29) .. (23.82,40.73)
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
 .. controls (299.75,218.92) and (310.74,234.04) .. (310.38,242.32)
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
current_src := "Romeo_entrance.th2 [3766]";
string area_border[];
area_border[1] := "l215-6016-7619";
drawoptions();
a_water(buildcycle(((279.96,285.16)
 .. controls (277.62,288.40) and (276.90,290.56) .. (274.92,293.26)
 .. controls (272.94,295.96) and (269.70,297.40) .. (267.72,298.85)
 .. controls (265.74,300.29) and (261.60,302.27) .. (257.46,302.81)
 .. controls (253.32,303.35) and (253.14,301.37) .. (248.82,298.31)
 .. controls (244.50,295.25) and (238.74,291.65) .. (235.50,287.51)
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
 .. controls (-13.80,26.87) and (-9.48,26.33) .. (-8.04,27.05)
 .. controls (-6.60,27.77) and (-3.00,32.99) .. (-1.56,35.69)
 .. controls (-0.12,38.39) and (0.42,38.03) .. (2.94,41.09)
 .. controls (5.46,44.15) and (9.78,46.49) .. (12.12,47.39)
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
 .. controls (232.07,214.43) and (237.47,216.95) .. (240.53,217.48)
 .. controls (243.59,218.02) and (246.29,223.06) .. (250.97,225.04)
 .. controls (255.65,227.02) and (256.01,225.76) .. (260.15,225.04)
 .. controls (264.29,224.32) and (268.79,223.78) .. (273.29,221.98)
 .. controls (277.79,220.18) and (282.11,221.44) .. (284.81,222.34)
 .. controls (287.51,223.24) and (293.45,228.82) .. (295.07,231.70)
 .. controls (296.69,234.58) and (304.08,244.12) .. (306.78,250.42)
 .. controls (309.48,256.72) and (305.88,260.50) .. (303.54,264.28)
 .. controls (301.20,268.06) and (298.14,270.40) .. (295.62,272.38)
 .. controls (293.10,274.36) and (288.78,277.60) .. (285.00,278.50)
 .. controls (281.22,279.40) and (282.30,281.92) .. cycle
)));
current_src := "Romeo_entrance.th2 [3580]";
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
l_pit(((-291.93,-15.44)
 .. controls (-290.49,-18.14) and (-285.81,-21.93) .. (-283.47,-23.37)
 .. controls (-281.13,-24.81) and (-276.81,-26.79) .. (-274.47,-26.61)
 .. controls (-272.13,-26.43) and (-270.87,-27.33) .. (-265.47,-24.27)
 .. controls (-260.06,-21.21) and (-257.90,-21.93) .. (-256.46,-18.33)
 .. controls (-255.02,-14.73) and (-249.08,-9.69) .. (-246.02,-9.69)
 .. controls (-242.96,-9.69) and (-242.78,-12.03) .. (-240.63,-15.45)
 .. controls (-238.47,-18.87) and (-238.65,-17.43) .. (-236.67,-21.21)
 .. controls (-234.69,-24.99) and (-230.02,-25.89) .. (-226.59,-25.89)
 .. controls (-222.45,-25.89) and (-219.39,-23.73) .. (-215.43,-21.75)
 .. controls (-211.47,-19.77) and (-208.59,-18.69) .. (-206.07,-17.43)
 .. controls (-203.55,-16.17) and (-197.97,-14.55) .. (-197.97,-14.55)
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
 .. controls (-253.57,76.72) and (-248.35,75.99) .. (-251.06,63.57)
 .. controls (-253.76,51.15) and (-252.32,44.67) .. (-251.42,31.35)
 .. controls (-250.52,18.03) and (-249.62,17.13) .. (-249.62,5.43)
 .. controls (-249.62,-6.27) and (-249.62,1.83) .. (-247.64,-4.65)
 .. controls (-245.66,-11.13) and (-244.40,-6.63) .. (-241.16,-7.53)
 .. controls (-237.92,-8.43) and (-233.97,-8.97) .. (-231.81,-8.61)
 .. controls (-229.65,-8.25) and (-224.25,-5.73) .. (-219.03,-4.11)
 .. controls (-213.81,-2.49) and (-213.80,0.57) .. (-210.02,7.05)
 .. controls (-206.24,13.53) and (-205.88,23.97) .. (-201.20,30.28)
 .. controls (-196.52,36.58) and (-194.35,47.02) .. (-192.01,52.42)
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
l_border_invisible(((-341.61,-294.44)
 .. controls (-340.53,-295.34) and (-333.87,-311.72) .. (-331.71,-315.86)
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
 .. controls (-320.36,-215.24) and (-324.50,-214.88) .. (-329.90,-216.32)
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
 .. controls (213.17,272.39) and (236.57,245.39) .. (241.61,239.63)
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
 .. controls (272.94,295.96) and (269.70,297.40) .. (267.72,298.85)
 .. controls (265.74,300.29) and (261.60,302.27) .. (257.46,302.81)
 .. controls (253.32,303.35) and (253.14,301.37) .. (248.82,298.31)
 .. controls (244.50,295.25) and (238.74,291.65) .. (235.50,287.51)
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
 .. controls (-13.80,26.87) and (-9.48,26.33) .. (-8.04,27.05)
 .. controls (-6.60,27.77) and (-3.00,32.99) .. (-1.56,35.69)
 .. controls (-0.12,38.39) and (0.42,38.03) .. (2.94,41.09)
 .. controls (5.46,44.15) and (9.78,46.49) .. (12.12,47.39)
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
 .. controls (232.07,214.43) and (237.47,216.95) .. (240.53,217.48)
 .. controls (243.59,218.02) and (246.29,223.06) .. (250.97,225.04)
 .. controls (255.65,227.02) and (256.01,225.76) .. (260.15,225.04)
 .. controls (264.29,224.32) and (268.79,223.78) .. (273.29,221.98)
 .. controls (277.79,220.18) and (282.11,221.44) .. (284.81,222.34)
 .. controls (287.51,223.24) and (293.45,228.82) .. (295.07,231.70)
 .. controls (296.69,234.58) and (304.08,244.12) .. (306.78,250.42)
 .. controls (309.48,256.72) and (305.88,260.50) .. (303.54,264.28)
 .. controls (301.20,268.06) and (298.14,270.40) .. (295.62,272.38)
 .. controls (293.10,274.36) and (288.78,277.60) .. (285.00,278.50)
 .. controls (281.22,279.40) and (282.30,281.92) .. cycle
));
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_rockborder(((271.50,303.71)
 -- (281.94,291.10)
 -- (293.82,295.78)
 -- (289.50,304.42)
 -- (279.06,310.18)
 -- cycle
));
endfig;
beginfig(18);
draw_upscrap(1)(1,((-460.06,-315.14)
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
 .. controls (-11.46,-8.59) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.66,39.29) .. (23.82,40.73)
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
 .. controls (299.75,218.92) and (310.74,234.04) .. (310.38,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
),
1,((280.32,318.83)
 .. controls (276.18,313.97) and (272.94,311.09) .. (266.82,307.31)
 .. controls (260.70,303.53) and (258.72,305.15) .. (253.50,304.07)
 .. controls (248.28,302.99) and (241.08,298.85) .. (237.30,293.63)
 .. controls (233.52,288.41) and (226.49,284.81) .. (225.05,279.95)
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
 .. controls (-25.32,41.26) and (-47.10,24.52) .. (-49.44,19.84)
 .. controls (-51.78,15.16) and (-66.90,-4.82) .. (-69.96,-9.86)
 .. controls (-73.02,-14.90) and (-76.98,-23.90) .. (-86.16,-26.60)
 .. controls (-95.34,-29.30) and (-104.16,-26.42) .. (-112.44,-33.44)
 .. controls (-120.72,-40.46) and (-126.84,-45.86) .. (-128.28,-47.84)
 .. controls (-129.72,-49.82) and (-136.20,-50.72) .. (-138.18,-51.08)
 .. controls (-140.16,-51.44) and (-143.40,-54.14) .. (-144.84,-59.54)
 .. controls (-146.28,-64.94) and (-150.24,-75.02) .. (-154.92,-79.52)
 .. controls (-159.60,-84.02) and (-159.96,-90.86) .. (-164.82,-94.46)
 .. controls (-169.68,-98.06) and (-175.63,-101.66) .. (-176.71,-104.90)
 .. controls (-177.79,-108.14) and (-179.95,-118.58) .. (-181.93,-120.92)
 .. controls (-183.91,-123.26) and (-196.15,-131.72) .. (-199.03,-133.52)
 .. controls (-201.91,-135.32) and (-211.09,-147.38) .. (-214.15,-148.10)
 .. controls (-217.22,-148.82) and (-221.90,-147.38) .. (-227.48,-152.96)
 .. controls (-233.06,-158.54) and (-235.94,-161.96) .. (-239.36,-164.30)
 .. controls (-242.78,-166.64) and (-248.90,-170.78) .. (-251.60,-171.50)
 .. controls (-254.30,-172.22) and (-257.71,-176.18) .. (-260.60,-176.18)
 .. controls (-263.48,-176.18) and (-266.00,-177.44) .. (-269.78,-177.44)
),
1,((-248.72,-170.42)
 .. controls (-248.18,-169.16) and (-247.10,-164.66) .. (-245.84,-159.98)
 .. controls (-244.58,-155.30) and (-247.10,-146.66) .. (-247.28,-140.90)
 .. controls (-247.46,-135.14) and (-247.64,-125.96) .. (-248.18,-120.93)
 .. controls (-248.72,-115.89) and (-245.49,-101.85) .. (-244.77,-98.61)
 .. controls (-244.05,-95.37) and (-237.93,-79.89) .. (-233.79,-77.01)
 .. controls (-229.65,-74.13) and (-215.25,-52.35) .. (-213.45,-47.31)
 .. controls (-211.65,-42.27) and (-202.38,-20.22) .. (-201.12,-15.90)
),
1,((-201.12,-15.90)
 .. controls (-199.86,-11.58) and (-195.26,3.46) .. (-190.40,11.02)
 .. controls (-185.54,18.58) and (-175.81,36.94) .. (-172.93,41.62)
 .. controls (-170.05,46.30) and (-154.57,75.28) .. (-153.31,78.16)
 .. controls (-152.05,81.04) and (-146.83,107.50) .. (-140.89,127.84)
 .. controls (-138.00,137.72) and (-138.10,149.98) .. (-138.86,156.06)
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
 .. controls (-284.36,73.84) and (-288.86,32.25) .. (-290.30,21.63)
 .. controls (-291.74,11.01) and (-289.77,-15.44) .. (-288.69,-19.94)
),
1,((-288.69,-19.94)
 .. controls (-287.61,-24.44) and (-283.46,-54.69) .. (-282.56,-57.39)
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
 .. controls (-318.38,-194.54) and (-321.08,-198.14) .. (-323.06,-201.92)
 .. controls (-325.05,-205.70) and (-332.60,-208.22) .. (-338.01,-209.84)
 .. controls (-343.41,-211.46) and (-354.39,-211.46) .. (-358.35,-211.10)
 .. controls (-362.31,-210.74) and (-380.85,-215.06) .. (-384.27,-216.32)
 .. controls (-387.69,-217.57) and (-411.99,-226.93) .. (-428.01,-236.29)
 .. controls (-444.03,-245.65) and (-442.05,-259.15) .. (-444.03,-265.27)
 .. controls (-446.01,-271.39) and (-447.99,-284.89) .. (-448.36,-289.03)
 .. controls (-448.72,-293.17) and (-454.66,-288.31) .. (-458.26,-288.85)
));
draw_downscrap;
endfig;
beginfig(19);
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
 .. controls (-284.36,73.84) and (-288.86,32.25) .. (-290.30,21.63)
 .. controls (-291.74,11.01) and (-289.77,-15.44) .. (-288.69,-19.94)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-201.12,-15.90)
 .. controls (-199.86,-11.58) and (-195.26,3.46) .. (-190.40,11.02)
 .. controls (-185.54,18.58) and (-175.81,36.94) .. (-172.93,41.62)
 .. controls (-170.05,46.30) and (-154.57,75.28) .. (-153.31,78.16)
 .. controls (-152.05,81.04) and (-146.83,107.50) .. (-140.89,127.84)
 .. controls (-138.00,137.72) and (-138.10,149.98) .. (-138.86,156.06)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-288.69,-19.94)
 .. controls (-287.61,-24.44) and (-283.46,-54.69) .. (-282.56,-57.39)
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
 .. controls (-318.38,-194.54) and (-321.08,-198.14) .. (-323.06,-201.92)
 .. controls (-325.05,-205.70) and (-332.60,-208.22) .. (-338.01,-209.84)
 .. controls (-343.41,-211.46) and (-354.39,-211.46) .. (-358.35,-211.10)
 .. controls (-362.31,-210.74) and (-380.85,-215.06) .. (-384.27,-216.32)
 .. controls (-387.69,-217.57) and (-411.99,-226.93) .. (-428.01,-236.29)
 .. controls (-444.03,-245.65) and (-442.05,-259.15) .. (-444.03,-265.27)
 .. controls (-446.01,-271.39) and (-447.99,-284.89) .. (-448.36,-289.03)
 .. controls (-448.72,-293.17) and (-454.66,-288.31) .. (-458.26,-288.85)
));
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-316.94,-168.80)
 -- (-322.16,-163.94)
));
drawoptions();
p_gradient((-433.06,-305.42),85.6,1.41,(0,0));
drawoptions();
p_gradient((-315.32,-174.38),60.6,1.00,(0,0));
ATTR__id := "l261-3264-5728";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-248.72,-170.42)
 .. controls (-248.18,-169.16) and (-247.10,-164.66) .. (-245.84,-159.98)
 .. controls (-244.58,-155.30) and (-247.10,-146.66) .. (-247.28,-140.90)
 .. controls (-247.46,-135.14) and (-247.64,-125.96) .. (-248.18,-120.93)
 .. controls (-248.72,-115.89) and (-245.49,-101.85) .. (-244.77,-98.61)
 .. controls (-244.05,-95.37) and (-237.93,-79.89) .. (-233.79,-77.01)
 .. controls (-229.65,-74.13) and (-215.25,-52.35) .. (-213.45,-47.31)
 .. controls (-211.65,-42.27) and (-202.38,-20.22) .. (-201.12,-15.90)
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
l_wall_bedrock(((280.32,318.83)
 .. controls (276.18,313.97) and (272.94,311.09) .. (266.82,307.31)
 .. controls (260.70,303.53) and (258.72,305.15) .. (253.50,304.07)
 .. controls (248.28,302.99) and (241.08,298.85) .. (237.30,293.63)
 .. controls (233.52,288.41) and (226.49,284.81) .. (225.05,279.95)
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
 .. controls (-25.32,41.26) and (-47.10,24.52) .. (-49.44,19.84)
 .. controls (-51.78,15.16) and (-66.90,-4.82) .. (-69.96,-9.86)
 .. controls (-73.02,-14.90) and (-76.98,-23.90) .. (-86.16,-26.60)
 .. controls (-95.34,-29.30) and (-104.16,-26.42) .. (-112.44,-33.44)
 .. controls (-120.72,-40.46) and (-126.84,-45.86) .. (-128.28,-47.84)
 .. controls (-129.72,-49.82) and (-136.20,-50.72) .. (-138.18,-51.08)
 .. controls (-140.16,-51.44) and (-143.40,-54.14) .. (-144.84,-59.54)
 .. controls (-146.28,-64.94) and (-150.24,-75.02) .. (-154.92,-79.52)
 .. controls (-159.60,-84.02) and (-159.96,-90.86) .. (-164.82,-94.46)
 .. controls (-169.68,-98.06) and (-175.63,-101.66) .. (-176.71,-104.90)
 .. controls (-177.79,-108.14) and (-179.95,-118.58) .. (-181.93,-120.92)
 .. controls (-183.91,-123.26) and (-196.15,-131.72) .. (-199.03,-133.52)
 .. controls (-201.91,-135.32) and (-211.09,-147.38) .. (-214.15,-148.10)
 .. controls (-217.22,-148.82) and (-221.90,-147.38) .. (-227.48,-152.96)
 .. controls (-233.06,-158.54) and (-235.94,-161.96) .. (-239.36,-164.30)
 .. controls (-242.78,-166.64) and (-248.90,-170.78) .. (-251.60,-171.50)
 .. controls (-254.30,-172.22) and (-257.71,-176.18) .. (-260.60,-176.18)
 .. controls (-263.48,-176.18) and (-266.00,-177.44) .. (-269.78,-177.44)
));
ATTR__id := "l87-5698-7070";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-460.06,-315.14)
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
 .. controls (-11.46,-8.59) and (-0.48,5.09) .. (2.04,8.87)
 .. controls (4.56,12.65) and (2.76,19.49) .. (2.40,22.19)
 .. controls (2.04,24.89) and (4.92,25.25) .. (7.44,26.69)
 .. controls (9.96,28.13) and (21.66,39.29) .. (23.82,40.73)
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
 .. controls (299.75,218.92) and (310.74,234.04) .. (310.38,242.32)
 .. controls (310.02,250.60) and (316.68,255.64) .. (317.22,263.74)
 .. controls (317.76,271.84) and (322.98,277.06) .. (324.42,277.78)
));
ATTR__id := "";
drawoptions();
p_entrance((319.02,313.06),129.9,2.00,(0,0));
endfig;
beginfig(20);
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
beginfig(21);
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
beginfig(22);
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
beginfig(23);
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
beginfig(24);
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
beginfig(25);
ATTR__survey := "Romeo_1_12.romeo";
current_src := "Romeo_1_12.th2 [303]";
string area_border[];
area_border[1] := "l43-3300-5252";
drawoptions();
a_pebbles(buildcycle(((34.09,215.46)
 .. controls (34.09,215.46) and (142.16,176.71) .. (166.48,81.40)
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
 -- (358.46,286.77)
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
 .. controls (-352.32,-392.31) and (-342.95,-380.04) .. (-325.65,-377.14)
 .. controls (-308.36,-374.24) and (-290.34,-372.06) .. (-281.70,-374.93)
 .. controls (-273.06,-377.81) and (-262.26,-379.97) .. (-258.67,-389.35)
 .. controls (-255.08,-398.72) and (-250.78,-418.20) .. (-248.63,-429.01)
 .. controls (-246.49,-439.83) and (-241.47,-462.91) .. (-248.69,-473.01)
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
 .. controls (34.09,215.46) and (142.16,176.71) .. (166.48,81.40)
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
 -- (358.46,286.77)
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
 .. controls (-352.32,-392.31) and (-342.95,-380.04) .. (-325.65,-377.14)
 .. controls (-308.36,-374.24) and (-290.34,-372.06) .. (-281.70,-374.93)
 .. controls (-273.06,-377.81) and (-262.26,-379.97) .. (-258.67,-389.35)
 .. controls (-255.08,-398.72) and (-250.78,-418.20) .. (-248.63,-429.01)
 .. controls (-246.49,-439.83) and (-241.47,-462.91) .. (-248.69,-473.01)
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
 .. controls (369.07,497.33) and (370.94,495.44) .. (370.74,492.27)
 .. controls (370.55,489.11) and (370.84,486.95) .. (368.93,485.98)
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
 .. controls (362.30,464.68) and (361.64,463.16) .. (361.91,461.15)
 .. controls (362.19,459.13) and (362.23,457.95) .. (360.28,456.55)
 .. controls (358.33,455.15) and (356.50,455.11) .. (354.51,454.38)
 .. controls (352.52,453.64) and (347.77,453.53) .. (347.77,453.53)
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
 .. controls (372.14,459.94) and (372.03,458.60) .. (370.22,458.41)
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
beginfig(26);
draw_upscrap(1)(1,((410.17,594.14)
 .. controls (406.27,592.25) and (404.58,594.81) .. (402.36,591.33)
 .. controls (399.46,586.77) and (391.89,571.32) .. (388.16,563.56)
 .. controls (384.59,556.13) and (368.66,520.10) .. (366.35,513.39)
 .. controls (364.07,506.76) and (352.71,463.53) .. (350.52,458.90)
 .. controls (348.30,454.22) and (345.16,427.77) .. (343.55,422.39)
 .. controls (341.94,416.99) and (337.44,400.26) .. (336.19,395.06)
 .. controls (334.95,389.87) and (335.37,380.42) .. (336.67,375.45)
 .. controls (337.98,370.49) and (344.37,363.42) .. (346.37,361.84)
 .. controls (348.37,360.26) and (356.67,359.58) .. (349.53,353.72)
 .. controls (342.35,347.83) and (333.13,346.50) .. (330.25,344.51)
 .. controls (327.37,342.53) and (316.53,341.01) .. (319.66,328.00)
 .. controls (322.79,314.94) and (325.30,310.47) .. (323.70,302.03)
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
 .. controls (-48.03,-34.45) and (-35.62,-20.42) .. (-32.38,-15.92)
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
 .. controls (434.86,517.33) and (453.91,558.23) .. (453.91,558.23)
));
draw_downscrap;
endfig;
beginfig(27);
ATTR__id := "";
ATTR__height := -1;
drawoptions();
l_wall_bedrock(((-120.78,-108.58)
 .. controls (-118.80,-104.43) and (-111.97,-97.42) .. (-108.55,-91.66)
 .. controls (-105.13,-85.91) and (-101.18,-83.04) .. (-95.80,-78.20)
 .. controls (-90.41,-73.36) and (-80.72,-65.84) .. (-76.05,-60.28)
 .. controls (-71.38,-54.72) and (-58.10,-42.71) .. (-53.06,-38.58)
 .. controls (-48.03,-34.45) and (-35.62,-20.42) .. (-32.38,-15.92)
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
 .. controls (434.86,517.33) and (453.91,558.23) .. (453.91,558.23)
));
drawoptions();
p_stalactites((-181.46,-28.86),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-160.62,-7.68),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-145.91,8.81),0.0,1.00,(0,0));
drawoptions();
p_stalactites((-127.95,27.10),0.0,1.00,(0,0));
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
p_stalactites((280.06,259.88),0.0,1.00,(0,0));
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
p_rimstonepool((190.04,223.48),92.5,1.00,(0,0));
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
l_wall_bedrock(((410.17,594.14)
 .. controls (406.27,592.25) and (404.58,594.81) .. (402.36,591.33)
 .. controls (399.46,586.77) and (391.89,571.32) .. (388.16,563.56)
 .. controls (384.59,556.13) and (368.66,520.10) .. (366.35,513.39)
 .. controls (364.07,506.76) and (352.71,463.53) .. (350.52,458.90)
 .. controls (348.30,454.22) and (345.16,427.77) .. (343.55,422.39)
 .. controls (341.94,416.99) and (337.44,400.26) .. (336.19,395.06)
 .. controls (334.95,389.87) and (335.37,380.42) .. (336.67,375.45)
 .. controls (337.98,370.49) and (344.37,363.42) .. (346.37,361.84)
 .. controls (348.37,360.26) and (356.67,359.58) .. (349.53,353.72)
 .. controls (342.35,347.83) and (333.13,346.50) .. (330.25,344.51)
 .. controls (327.37,342.53) and (316.53,341.01) .. (319.66,328.00)
 .. controls (322.79,314.94) and (325.30,310.47) .. (323.70,302.03)
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
beginfig(28);
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
beginfig(29);
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
beginfig(30);
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
beginfig(31);
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
beginfig(32);
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
beginfig(33);
s_northarrow(0);
endfig;
beginfig(34);
s_scalebar(10, 1, "\thfb\char109 \mainfont{}");
endfig;
background:=(1.00000,1.00000,1.00000);
transparency:=false;
beginfig(35);
clean_legend_box;
drawoptions();
p_entrance((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(36);
clean_legend_box;
drawoptions();
l_wall_bedrock(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(37);
clean_legend_box;
drawoptions();
l_wall_unsurveyed(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(38);
clean_legend_box;
drawoptions();
l_wall_flowstone(((-.3,0.5) .. (.3,.3) .. (.7,.7) .. (1.3,.5)) inscale);
draw_legend_box;
endfig;
beginfig(39);
clean_legend_box;
drawoptions();
p_airdraught((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(40);
clean_legend_box;
drawoptions(withcolor HelpSymbolColor);
l_wall_bedrock(((0,.2){dir 30} .. {dir 0}(.5,.4)) inscale);
l_wall_bedrock(((.5,.6){dir 180} .. {dir 210}(0,.8)) inscale);
drawoptions();
drawoptions();
p_claychoke((.6,.5) inscale,270.0,1.0,(0,1));
draw_legend_box;
endfig;
beginfig(41);
clean_legend_box;
drawoptions();
l_floorstep((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(42);
clean_legend_box;
drawoptions();
l_pit((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
drawoptions();
beginfig(43);
clean_legend_box;
drawoptions();
p_gradient((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(44);
clean_legend_box;
drawoptions();
l_rockborder(((.16,.36) -- (.61,.21) -- (.91,.46) -- (.84,.78) -- (.38,.86) -- (.20,.55) -- cycle) inscale)draw_legend_box;
endfig;
beginfig(45);
clean_legend_box;
drawoptions();
p_guano((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(46);
clean_legend_box;
drawoptions();
l_border_visible((((.85,.5){dir 90} .. (.5,.85){dir 180} .. (.4,.15){dir 0} .. cycle) inscale));
draw_legend_box;
endfig;
beginfig(47);
clean_legend_box;
drawoptions();
a_water(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(48);
clean_legend_box;
drawoptions();
a_sump(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(49);
clean_legend_box;
drawoptions();
a_sand(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(50);
clean_legend_box;
drawoptions();
a_clay(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(51);
clean_legend_box;
drawoptions();
a_pebbles(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(52);
clean_legend_box;
drawoptions();
a_debris(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(53);
clean_legend_box;
drawoptions();
a_flowstone(buildcycle((((-1,0) -- (1,0) -- (1,1) -- (0,1) -- (0,-1))  inscale)));
draw_legend_box;
endfig;
beginfig(54);
clean_legend_box;
drawoptions();
a_blocks(buildcycle((((-4,-4) -- (4,-4) -- (4,4) -- (-4,4) -- (-4,-4))  inscale)));
draw_legend_box;
endfig;
beginfig(55);
clean_legend_box;
drawoptions();
p_waterflow_permanent((0.5,0.5) inscale,270.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(56);
clean_legend_box;
drawoptions();
l_flowstone((((.1,.6) .. (.5,.4) .. (.9,.6)) inscale));
draw_legend_box;
endfig;
beginfig(57);
clean_legend_box;
drawoptions();
p_stalactite((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(58);
clean_legend_box;
drawoptions();
p_stalactites((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(59);
clean_legend_box;
drawoptions();
p_stalagmite((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(60);
clean_legend_box;
drawoptions();
p_stalagmites((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(61);
clean_legend_box;
drawoptions();
p_pillar((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(62);
clean_legend_box;
drawoptions();
p_curtain((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(63);
clean_legend_box;
drawoptions();
p_sodastraw((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(64);
clean_legend_box;
drawoptions();
p_crystal((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(65);
clean_legend_box;
drawoptions();
p_rimstonepool((0.5,0.5) inscale,0.0,1.0,(0,0));
draw_legend_box;
endfig;
beginfig(66);
s_hgrid(-1, -1, 141.73228, 141.73228);
endfig;
beginfig(67);
s_hgrid(0, -1, 141.73228, 141.73228);
endfig;
beginfig(68);
s_hgrid(1, -1, 141.73228, 141.73228);
endfig;
beginfig(69);
s_hgrid(-1, 0, 141.73228, 141.73228);
endfig;
beginfig(70);
s_hgrid(0, 0, 141.73228, 141.73228);
endfig;
beginfig(71);
s_hgrid(1, 0, 141.73228, 141.73228);
endfig;
beginfig(72);
s_hgrid(-1, 1, 141.73228, 141.73228);
endfig;
beginfig(73);
s_hgrid(0, 1, 141.73228, 141.73228);
endfig;
beginfig(74);
s_hgrid(1, 1, 141.73228, 141.73228);
endfig;
end;
