% Patterns similar to standard definition of pattern_water_UIS and pattern_sump_UIS
% Gives b&w shaded symbols with borders, unless custom colours are defined
% in which case colour backgrounds defined in LayoutColourSymbols are used
%  code metapost
  beginpattern(pattern_water);
      draw origin--10up withpen pensquare scaled (0.04u); % line thickness
      patternxstep(.50u);                                 % spacing
      patterntransform(identity rotated 45);
  endpattern;
  
  beginpattern(pattern_sump);
      draw origin--(0,.50u) withpen pensquare scaled (0.04u);
      draw origin--(.50u,0) withpen pensquare scaled (0.04u);
      patterntransform(identity rotated 45);	
  endpattern;
  
  
  def p_water (expr pos,theta,sc,al)=
  %Bruce Mutton 2010.06.20 for Therion 5.3.8
      U:=(.425u,.3u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      pickup PenD;
      p:=fullcircle xscaled (1.2u) yscaled (0.8u) randomized (0.1u) rotated uniformdeviate (-45);
      if known colour_water_bg: thfill p withcolor colour_water_bg; else: thfill p withcolor white; fi; 
      thfill p withpattern pattern_water; %%% withcolor black;  %but with failed attempt at black hatch
      thdraw p;   %outline
      enddef; 
  
  def a_water (expr Path) =
  %Bruce Mutton 2010.06.20 for Therion 5.3.8
    T:=identity;
    thclean Path;
    pickup PenD;
    if known colour_water_bg: thfill Path withcolor colour_water_bg; else: thfill Path withcolor white; fi; 
    thfill Path withpattern pattern_water;  
    %%thdraw Path;  %outline, not needed as area drawn is defined by line border anyway
     %and border can be made invisible with subtype invisible where water meets sump in elevation
  enddef;
  
  def a_sump (expr Path) =
  %Bruce Mutton 2010.06.20 for Therion 5.3.8
    T:=identity;
    thclean Path;
    pickup PenD;
    if known colour_sump_bg:  thfill Path withcolor colour_sump_bg; else: thfill Path withcolor 0.7[white,black]; fi;
    thfill Path withpattern pattern_sump;  
    %%thdraw Path;  %outline, not needed as area drawn is defined by line border anyway
     %and border can be made invisible with subtype invisible where water meets sump in elevation
  enddef;

  def s_scalebar (expr l, units, txt) =
    begingroup
      interim warningcheck:=0;
      tmpl:=l / Scale * cm * units / 2;
      tmpx:=l / Scale * cm * units / 5;
      tmph:=10bp; % bar height
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
          label.top(thTEX(decimal (i)) scaled 1.8, (tmpx,0));
        endfor;
        label.top(thTEX(decimal (l) & "\thinspace" & txt) scaled 1.8,(tmpl,0));
        label.bot(thTEX("Original Scale = 1 : " & decimal round(Scale*100)) scaled 1.8, (.6cm,-0.6cm)) ;
    endgroup;
  enddef;

%  endcode
