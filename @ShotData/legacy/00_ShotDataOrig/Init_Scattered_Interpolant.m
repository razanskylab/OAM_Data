% [out] = Init_Scattered_Interpolant(SDO,In) @ SDO
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Init_Scattered_Interpolant(SDO)
  if any(strcmp(SDO.reMapMethod,{'linear','par-linear'})) %
    SDO.Print_Indent();
    tic;
    SDO.VPrintF('Initializing scatteredInterpolant...');
    SDO.ScatInterp = scatteredInterpolant(double(SDO.Pos.xS)',double(SDO.Pos.yS)',zeros(1,SDO.nShots)');
      % scatteredInterpolant expects double vectors of format nShots x 1, i.e. column-vector format
    SDO.ScatInterp.Method = 'linear'; % 'nearest' we can do much faster, 'cubic' is not physical
    SDO.ScatInterp.ExtrapolationMethod = 'nearest'; % this way we don't get NaNs
    SDO.Done();
  end

  % whnen using parallel linear int make sure to start parallel pool
  % (should be running already)
  if strcmp(SDO.reMapMethod,'par-linear') %
    SDO.Handle_Parallel_Workers();
  end
end
