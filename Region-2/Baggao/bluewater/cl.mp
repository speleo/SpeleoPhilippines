    #Code to change grid symbols from cross hairs to continuous lines
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
