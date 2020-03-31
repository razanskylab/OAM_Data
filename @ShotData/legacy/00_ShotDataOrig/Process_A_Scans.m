% [out] = Reduce_Data(SDO) @ SDO
% get rid of data we don't need/want to speed up later interpolation
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018


function [] = Process_A_Scans(SDO)
  SDO.Sync_Subclass_Settings(); % be safe, update the subclass outputs

  if SDO.verboseOutput
    SDO.Hor_Div();
    SDO.VPrintF('Processing A-Scans\n');
  else
    SDO.PrintF('Processing A-Scans...\n');
  end

  % TODO remove jitter! And only remove, i.e. jitter has to be provided
  % externally via variable or property
  if SDO.correctJitter
    SDO.Correct_Shot_Jitter();
  end

  % fixme
  SDO.Resample_Raw(); % does not do anything of

   % filter?
  % SDO.Filter_A_Scans();
  % hold on;

  % TODO correct laser fluctuations
  % if SDO.correctLaserFluctuations
  %   SDO.PDE.Correct_Laser_Fluctuations();
  % end

  SDO.raw = SDO.Apply_Signal_Polarity(SDO.raw); % at least output polarity info, so no if/else here


end
