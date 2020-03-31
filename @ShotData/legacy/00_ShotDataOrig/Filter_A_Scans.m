% Filter_A_Scans(SDO) @ SDO
%
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Filter_A_Scans(SDO)
  SDO.Sync_Subclass_Settings();
  SDO.Filter.df = SDO.df;
  SDO.Filter.Define();
  SDO.raw = SDO.Filter.Apply(SDO.raw);
end
