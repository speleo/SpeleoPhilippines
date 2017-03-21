### index of file options from _layouts.mp
  #copy custom_water_blue
  #copy custom_entrance_theta
  #copy custom_scalebar_large_format
  #copy custom_scalebar_medium_format
  #copy custom_scalebar
  #copy custom_legend_large_format
  #copy custom_legend_large_format_5U
  #copy custom_legend_large_format_20U
  #copy custom_grid_2_continuous
  #copy custom_centerline_2_continuous
  #copy custom_bats
  #copy custom_north_arrow_150
  #copy custom_north_arrow_300
  #copy custom_north_arrow_600
  #copy custom_northarrow_large
  #copy custom_line_doline


#############################################################################################################################
layout custom_water_blue
  code metapost
    # code to change the colour of the water
    def a_water (expr p) =
        T:=identity;
        thfill p withcolor (0.1, 0.2, 0.8);
    enddef;
  endcode
endlayout

#############################################################################################################################
layout custom_entrance_theta
  code metapost
    # Code to define an entrance symbol as a theta inside a diamond (Dave Clucas 2014)   
    def p_entrance (expr pos,theta,sc,al)=
      U:=(0.8u,2u);
      T:=identity aligned al rotated theta scaled sc shifted pos;
      path p;
      p = (-1.2u,-1u) -- (-0.8u,-1u){dir 135} .. (0u,1u) .. {dir 225}(0.8u,-1u) -- (1.2u,-1u);
      thdraw p withpen PenA;
      thdraw unitsquare scaled 4u shifted (-2u,-2u) rotated 45 withpen PenA;
    enddef;
  endcode
endlayout


#############################################################################################################################
layout custom_scalebar_large_format_origional
  code metapost
  %  Change the scalebar to this one from this example
  %
  %  https://therion.speleo.sk/wiki/metapost?s[]=scalebar

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
        label.bot(thTEX("Original Scale = 1 : " & decimal round(Scale*100)) scaled 5.6, (.6cm,-1.6cm)) transformed T;
      endgroup;
    enddef;
  endcode
endlayout

#############################################################################################################################
layout custom_scalebar_large_format
  code metapost
  %  Change the scalebar to this one from this example
  %
  %  https://therion.speleo.sk/wiki/metapost?s[]=scalebar

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
        label.bot(thTEX("Original Scale = 1 : " & decimal round(Scale*100)) scaled 5.6, (.6cm,-1.6cm)) ;
      endgroup;
    enddef;
  endcode
endlayout

#############################################################################################################################
layout custom_scalebar_medium_format
  code metapost
  %  Change the scalebar to this one from this example
  %
  %  https://therion.speleo.sk/wiki/metapost?s[]=scalebar
  %
  def s_scalebar (expr l, units, txt) =
    begingroup
      interim warningcheck:=0;
      tmpl:=l / Scale * cm * units / 2;
      tmpx:=l / Scale * cm * units / 5;
      tmph:=15bp; % bar height
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
        label.bot(thTEX("Original Scale = 1 : " & decimal round(Scale*100)) scaled 1.8, (.6cm,-1.6cm)) ;
    endgroup;
  enddef;
  endcode
endlayout

#############################################################################################################################
layout custom_scalebar
  code metapost
  %  Change the scalebar to this one from this example
  %
  %  https://therion.speleo.sk/wiki/metapost?s[]=scalebar
  %
  def s_scalebar (expr l, units, txt) =
    begingroup
      interim warningcheck:=0;
      tmpl:=l / Scale * cm * units / 2;
      tmpx:=l / Scale * cm * units / 5;
      tmph:=5bp; % bar height
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
        label.top(thTEX(decimal (i)),(tmpx,0));
      endfor;
      label.top(thTEX(decimal (l) & "\thinspace" & txt),(tmpl,0));
      label.bot(thTEX("Original Scale = 1 : " & decimal round(Scale*100)),(0,-tmph));
    endgroup;
  enddef;
  endcode
endlayout


#############################################################################################################################


layout custom_legend_large_format
  code metapost
    % code to make the legend boxes much bigger
    %  
    def draw_legend_box =
        %make the objects in the legend boxes bigger
        currentpicture := currentpicture scaled 3.4;
        clip currentpicture to unitsquare scaled 10u;
        drawoptions();
        pickup PenB;
        draw unitsquare scaled 10u ;
    enddef;

    %clear the background of the larger legend boxes    
    def clean_legend_box =
        unfill unitsquare scaled 10u;
    enddef;
    
    %change the value of inscale to fill the legend boxes
    def inscale = 
        xscaled legend_scale yscaled (0.618*legend_scale)
        %xscaled legend_scale yscaled legend_scale
     enddef;

  endcode
endlayout

#############################################################################################################################


layout custom_legend_large_format_5U
  code metapost
    % code to make the legend boxes much bigger
    %  
    def draw_legend_box =
        %make the objects in the legend boxes bigger
        currentpicture := currentpicture scaled 1.7;
        clip currentpicture to unitsquare scaled 5u;
        drawoptions();
        pickup PenB;
        draw unitsquare scaled 5u ;
    enddef;

    %clear the background of the larger legend boxes    
    def clean_legend_box =
        unfill unitsquare scaled 5u;
    enddef;
    
    %change the value of inscale to fill the legend boxes
    def inscale = 
        xscaled legend_scale yscaled (0.618*legend_scale)
        %xscaled legend_scale yscaled legend_scale
     enddef;

  endcode
endlayout

#############################################################################################################################
layout custom_legend_large_format_20U
  code metapost
    % code to make the legend boxes much bigger
    %
    def draw_legend_box =
        %make the objects in the legend boxes bigger
        currentpicture := currentpicture scaled 7.0;
        clip currentpicture to unitsquare scaled 20u;
        drawoptions();
        pickup PenB;
        draw unitsquare scaled 20u ;
    enddef;

    %clear the background of the larger legend boxes    
    def clean_legend_box =
        unfill unitsquare scaled 20u;
    enddef;
    
    %change the value of inscale to fill the legend boxes
    def inscale = 
        %xscaled legend_scale yscaled (0.618*legend_scale)
        xscaled legend_scale yscaled legend_scale
     enddef;

  endcode
endlayout

#############################################################################################################################
layout custom_grid_2_continuous
  grid bottom
  code metapost
    %    Code to change grid symbols from cross hairs to continuous lines
    %    from
    %    http://therion.speleo.sk/wiki/doku.php/metapost
    %
    def s_hgrid (expr xpos, ypos, xsize, ysize) =
      pickup PenD;
      draw (
        if xpos < 0: 0 else: -xsize/2 fi, 0
      ) -- (
        if xpos > 0: 0 else: xsize/2 fi, 0
      ) withcolor 0.1black+0.5white;
      draw (
        0, if ypos < 0: 0 else: -ysize/2 fi
      ) -- (
        0, if ypos > 0: 0 else: ysize/2 fi
      ) withcolor 0.1black+0.5white;
    enddef;
    
  endcode
endlayout

#############################################################################################################################
layout custom_centerline_2_continuous
  code metapost
    # change centre line to continuous
    def l_survey_cave (expr p) =
        draw p withpen PenD withcolor (0.6, 0.6, 0.6);
    enddef;
  endcode
endlayout

#############################################################################################################################
layout custom_bats
  code metapost
    %  Bat: point, line, area defination
    %
    %  http://therion.speleo.sk/wiki/doku.php/metapost
      path bat_path_x;
      bat_path_x := (160.43589,619.76148) 
      .. controls (200.83034,598.56215) and (225.01974,599.82632) .. (242.33709,601.15842) 
      .. controls (250.91988,585.02142) and (280.12279,545.7622) .. (328.92385,566.52372) 
      .. controls (343.18917,529.89929) and (387.77695,513.04018) .. (453.54702,518.36185) 
      .. controls (456.6654,525.97557) and (466.09064,533.43257) .. (471.27843,523.05007) 
      .. controls (463.85291,520.67657) and (466.71891,517.42483) .. (471.63814,522.23522) 
      .. controls (472.87859,519.83044) and (472.11254,517.25674) .. (467.00984,516.24193) 
      .. controls (498.08181,494.38071) and (518.37927,488.7935) .. (554.08261,484.34703) 
      .. controls (536.23968,468.87122) and (526.7451,451.32142) .. (536.0878,433.78585) 
      .. controls (539.04313,428.23891) and (549.65293,437.81051) .. (550.08905,431.99134) 
      .. controls (543.35122,428.68782) and (547.16851,429.31755) .. (550.93619,430.90592) 
      .. controls (555.01514,419.20795) and (542.29889,420.82043) .. (539.21019,422.32967) 
      .. controls (526.80565,412.03922) and (538.14174,362.22955) .. (562.04206,325.41289) 
      .. controls (560.70416,305.4475) and (552.94665,275.48765) .. (596.42383,240.15823) 
      .. controls (586.13796,214.86512) and (584.21841,176.344) .. (618.88684,158.99293) 
      .. controls (600.38363,161.42082) and (571.90452,163.00167) .. (555.87287,173.29962) 
      .. controls (533.80922,180.31406) and (511.7587,189.77279) .. (494.76462,217.75852) 
      .. controls (469.02274,260.15007) and (465.60841,280.08537) .. (466.27659,287.73284) 
      .. controls (467.27295,299.13663) and (456.20597,295.4343) .. (455.42733,284.84646) 
      .. controls (447.034,297.47822) and (465.71846,292.96944) .. (457.40227,311.17742) 
      .. controls (451.51715,333.88534) and (454.55183,344.68208) .. (455.22274,365.27634) 
      .. controls (445.59186,380.66207) and (438.52169,394.98144) .. (432.56329,406.97544) 
      .. controls (421.27321,411.75599) and (411.86904,413.85884) .. (403.92838,423.33244) 
      .. controls (391.19793,418.79449) and (380.875,414.46152) .. (373.6673,409.41976) 
      .. controls (365.11095,413.84661) and (372.76761,437.1554) .. (372.88328,437.30963) 
      -- (360.72573,447.88215) 
      .. controls (360.72573,447.88215) and (348.36583,439.38367) .. (342.32921,440.26049) 
      .. controls (340.52016,451.25937) and (343.58923,463.9528) .. (354.67087,475.2679) 
      .. controls (341.63825,482.57642) and (339.10347,494.24676) .. (313.80723,490.57484) 
      .. controls (304.61922,489.24114) and (282.31298,490.61764) .. (258.32359,496.84657) 
      .. controls (246.18809,499.99759) and (248.48311,482.8706) .. (236.36849,493.22467) 
      .. controls (239.32461,491.85429) and (242.55704,492.01948) .. (245.59044,495.64662) 
      .. controls (248.83726,499.52895) and (249.4495,502.08244) .. (244.59097,503.87878) 
      .. controls (221.93401,514.80409) and (190.83965,541.85436) .. (178.69512,574.11392) 
      .. controls (176.80431,577.00681) and (162.4873,600.33708) .. cycle;
      path bat_path_bb;
      bat_path_bb = bbox bat_path_x;
      path bat_path;
      bat_path = bat_path_x shifted (-(llcorner bat_path_bb) - (urcorner bat_path_bb - llcorner bat_path_bb) / 2.0) scaled (1u / ((xpart urcorner bat_path_bb) - (xpart llcorner bat_path_bb))) rotated 210;

    
    def p_u_bat(expr pos, theta, sc, al) =
      T := identity shifted pos;
      thfill (bat_path scaled 2.0) withcolor black;
    enddef;
    
    def l_u_bat(expr P) =
      T:=identity;
      cas := 0;
      dlzka := arclength P;
      mojkrok:=adjust_step(dlzka, 1.0u);
      pickup PenD;
      forever:
        t := arctime cas of P;
        thfill bat_path scaled 0.5 shifted (point t of P) withcolor black;
        cas := cas + mojkrok;
        exitif cas > dlzka + (mojkrok / 3); % for rounding errors
      endfor;
    enddef;
  
    % bat pattern
      beginpattern(pattern_bat);
      fill bat_path withcolor black;
    endpattern;

    % bat area symbol
      def a_u_bat (expr Path) =
      T:=identity;
      thclean Path;
      thfill Path withpattern pattern_bat;
    enddef;

    def l_u_bat_legend =
      l_u_bat(((.2,.2) -- (.8,.8)) inscale)
    enddef;

  endcode
endlayout

#############################################################################################################################

layout custom_north_arrow_150
  code metapost
    % code to make a groovy North Arrow
    %

    def s_northarrow (expr rot) =
      T:=identity;
      picture tmp_pic;
      tmp_pic = image (
        begingroup
          interim defaultscale:=13;
          label.top("N", origin shifted (0,22cm));
        endgroup;
        thdraw (-4cm,4cm)--(0,20cm)--(4cm,4cm)--(20cm,0cm)--(4cm,-4cm)--(0,-20cm)--(-4cm,-4cm)--(-20cm,0)--cycle;
        thfill (-4cm,4cm)--(0,20cm)--(0,0)--cycle;
        thfill (4cm,-4cm)--(0,-20cm)--(0,0)--cycle;
        thfill (4cm,4cm)--(20cm,0)--(0,0)--cycle;
        thfill (-4cm,-4cm)--(-20cm,0)--(0,0)--cycle;
      );
      draw tmp_pic scaled 0.15 rotatedaround(origin, -rot);
    enddef; 
  endcode
endlayout

#############################################################################################################################

layout custom_north_arrow_300
  code metapost
    % code to make a groovy North Arrow
    %

    def s_northarrow (expr rot) =
      T:=identity;
      picture tmp_pic;
      tmp_pic = image (
        begingroup
          interim defaultscale:=13;
          label.top("N", origin shifted (0,22cm));
        endgroup;
        thdraw (-4cm,4cm)--(0,20cm)--(4cm,4cm)--(20cm,0cm)--(4cm,-4cm)--(0,-20cm)--(-4cm,-4cm)--(-20cm,0)--cycle;
        thfill (-4cm,4cm)--(0,20cm)--(0,0)--cycle;
        thfill (4cm,-4cm)--(0,-20cm)--(0,0)--cycle;
        thfill (4cm,4cm)--(20cm,0)--(0,0)--cycle;
        thfill (-4cm,-4cm)--(-20cm,0)--(0,0)--cycle;
      );
      draw tmp_pic scaled 0.25 rotatedaround(origin, -rot);
    enddef;    
  endcode
endlayout

#############################################################################################################################


layout custom_north_arrow_600
  code metapost
    % code to make a groovy North Arrow
    %

    def s_northarrow (expr rot) =
      T:=identity;
      picture tmp_pic;
      tmp_pic = image (
        begingroup
          interim defaultscale:=13;
          label.top("N", origin shifted (0,22cm));
        endgroup;
        thdraw (-4cm,4cm)--(0,20cm)--(4cm,4cm)--(20cm,0cm)--(4cm,-4cm)--(0,-20cm)--(-4cm,-4cm)--(-20cm,0)--cycle;
        thfill (-4cm,4cm)--(0,20cm)--(0,0)--cycle;
        thfill (4cm,-4cm)--(0,-20cm)--(0,0)--cycle;
        thfill (4cm,4cm)--(20cm,0)--(0,0)--cycle;
        thfill (-4cm,-4cm)--(-20cm,0)--(0,0)--cycle;
      );
      draw tmp_pic scaled 0.5 rotatedaround(origin, -rot);
    enddef;   
  endcode
endlayout

##############################################################################################################################
layout custom_northarrow_large
  code metapost
    # Re-define North arrow to make it bigger
    def s_northarrow (expr rot) =
         T:=identity scaled 0.7 rotated -rot;
	 thdraw (-1cm,-1cm)--(0,5cm)--(1cm,-1cm)--(0,0cm)--cycle;
	 thfill (-1cm,-1cm)--(0,5cm)--(0,0cm)--cycle;
    enddef;
  endcode
endlayout

#############################################################################################################################
layout custom_line_doline
  code metapost
   def l_u_doline (expr P) =
    T:=identity;
    laenge:= arclength P;
    symsize:=adjust_step(laenge,2u);
    triangle_width:=symsize/10;
    cur:=(symsize-triangle_width)/2;
    pickup PenC;
    forever:
      t1 := arctime (cur) of P;
      t  := arctime (cur + triangle_width/2) of P;
      t2 := arctime (cur + triangle_width) of P;
        thfill (subpath (t1,t2) of P) -- 
          ((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
          cycle;
        thdraw (point t2 of P) --((point t of P) + symsize/2 * unitvector(thdir(P,t) rotated 90)) -- 
          (point t1 of P) withcolor (0.5, 0, 0);
      cur := cur + symsize;
      exitif cur > laenge - (1*symsize/3); % for rounding errors
      t1:=arctime (cur) of P;
    endfor;
  enddef;
  endcode
endlayout
#############################################################################################################################  
