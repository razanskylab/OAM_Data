% [out] = Apply_Filter(SDO,In) @ SDO
% define and apply filter to raw data 
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Apply_Filter(SDO)
  SDO.Sync_Subclass_Settings();
  SDO.Filter.Define();
  SDO.raw = SDO.Filter.Apply(SDO.raw);
end
