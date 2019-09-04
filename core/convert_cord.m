function [y,x]=convert_cord(w,ind,bdr)
  w_b=w+bdr*2;
  row=floor(ind/w_b);
  col=round(ind-row*w_b);
  y=row-bdr+1;
  x=col-bdr+1;
return