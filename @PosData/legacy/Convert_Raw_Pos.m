% [out] = Convert_Raw_Pos(Pos,In) @ Pos
% converts raw laser read out in volts to actual position based
% on the info stored in the XX file
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018


function [xS] = Convert_Raw_Pos(Pos,rawPos)
  xS = [];
  % use already loaded raw data if no rawPos is explictly provided
  if nargin == 1
    rawPos = Pos.xSRaw;
  end

  load('pFit.mat','pFit'); % poly fit to convert laser sensor voltage to stage position
  if nargin == 2
    Pos.xS = polyval(pFit, rawPos);
  elseif ~isempty(Pos.xSRaw)
    Pos.xS = polyval(pFit, Pos.xSRaw);
  else
    Pos.VPrintF('Can''t convert raw position without raw data!\n');
  end

  if nargout
    xS = Pos.xS;
  end

end
