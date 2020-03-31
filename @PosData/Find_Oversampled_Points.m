% [out] = Function_Name(Pos,In) @ Pos
% calculate step size between adjacent steps and keep only those shots
% where the step size is larger than targetStepSize
% default is dr - 20% when no targetStepSize is provided
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [keepIdx] = Find_Oversampled_Points(Pos,targetStepSize)
  t1 = tic;
  if nargin == 1
    dr = Pos.dr*0.4; % a little less than target step size to be on save side
  else
    dr = targetStepSize;
  end
  Pos.VPrintF('Finding shots with step size < %2.1f um...',dr*1e3);

  stepSize = zeros(Pos.nShots-1,1);
  for iPoint = 1:Pos.nShots-1
    stepSize(iPoint) = sqrt((Pos.xS(iPoint) - Pos.xS(iPoint+1)).^2 + (Pos.yS(iPoint) - Pos.yS(iPoint+1)).^2);
  end
  sumStepSize = 0;
  keepIdx = false(size(Pos.xS));
  for iPoint = 1:Pos.nShots-1
    sumStepSize = sumStepSize + stepSize(iPoint); % cumsum
    if sumStepSize > dr
      sumStepSize = 0;
      keepIdx(iPoint) = true;
    end
  end
  Pos.Done(t1);

end
