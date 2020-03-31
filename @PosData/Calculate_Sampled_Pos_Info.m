% [out] = Calculate_Sampled_Pos_Info(Pos,In) @ Pos
% calculate important position info and write to the setAccess = private
% properties xSCtr, xSWidth, xSRoi, maxVel
% do it only once so we are efficient
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Calculate_Sampled_Pos_Info(Pos);
  tic;
  Pos.VPrintF('Calculating sampled position info...');

  % calculate things for x-stage
  minX = min(Pos.xSSmooth);
  maxX = max(Pos.xSSmooth);
  Pos.xSCtr = mean([minX maxX]);
  Pos.xSWidth = maxX - minX;
  Pos.xSRoi = [minX maxX];
  Pos.maxVel(1) = max(Pos.xVel);
  Pos.maxDr(1) = Pos.maxVel(1)*Pos.dt;
  x = Pos.xSSmooth - mean(Pos.xSSmooth); % make zero centerd
  Pos.nXSBscans = sum(abs(diff(x>0))); % count zero crossings


  % calculate things for y-stage
  minY = min(Pos.yS);
  maxY = max(Pos.yS);
  Pos.ySCtr = mean([minY maxY]);
  Pos.ySWidth = maxY - minY;
  Pos.ySRoi = [minY maxY];
  Pos.maxVel(2) = max(Pos.yVel);
  Pos.maxDr(2) = Pos.maxVel(2)*Pos.bScanPeriod;
  Pos.Done();

end
