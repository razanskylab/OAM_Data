% [] = Crop(SDO) @ SDO
% only Crop if not already cropped
% otherwise use Crop_A_Scans
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function Crop(SDO)
  if ~SDO.isCropped
    SDO.Crop_A_Scans(SDO.zRange);
  else
    SDO.VPrintF('Looks like data was already cropped!');
  end
end
