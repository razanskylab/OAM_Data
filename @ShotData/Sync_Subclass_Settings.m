% Sync_Subclass_Settings(SDO) @ SDO
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Sync_Subclass_Settings(SDO)
  if SDO.dt
    SDO.Filter.df = 1./SDO.dt;
  end
  SDO.Filter.silent = SDO.silent;
  SDO.Filter.verboseOutput = SDO.verboseOutput;
  SDO.Filter.verbosePlotting = SDO.verbosePlotting;

  SDO.Pos.silent = SDO.silent;
  SDO.Pos.verboseOutput = SDO.verboseOutput;
  SDO.Pos.verbosePlotting = SDO.verbosePlotting;
end
