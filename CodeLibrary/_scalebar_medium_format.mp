%  Change the scalebar to this one from this example
%
%  http://therion.speleo.sk/wiki/doku.php/metapost

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
          label.top(thTEX(decimal (i)) scaled 2.6, (tmpx,0));
        endfor;
        label.top(thTEX(decimal (l) & "\thinspace" & txt) scaled 2.6,(tmpl,0));
        label.bot(thTEX("Original Scale = 1 : " & decimal round(Scale*100)) scaled 2.6, (.6cm,-1.6cm)) transformed T;
      endgroup;
    enddef;
