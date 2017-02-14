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
