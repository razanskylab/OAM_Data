% [out] = Remap_To_Volume(SDO,In) @ SDO
% text here
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Remap_To_Volume(SDO)
  SDO.Sync_Subclass_Settings(); % be safe, update the subclass outputs

  SDO.VPrintF('Remapping 2D shot data to regular 3D volume:\n');
  % Starting the interpolation fun...
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % old, fast but inacurate nearest neighbor interpolation %%%%%%%%%%%%%%%%%%%%%
  % if (Conf.interpolation == 0)
  switch SDO.reMapMethod
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'reshape' % simplest but by far fastest int. method
    tic;
    SDO.VPrintF('   Reshaping...');
    SDO.vol = reshape(SDO.raw,size(SDO.raw,1),SDO.Pos.nSteps(1),SDO.Pos.nSteps(2));
    % we scan back and forth, this flips every second line to allign them
    SDO.VPrintF('Y-Axis flipping...');
    SDO.vol(:, :, 1:2:end) = flip(SDO.vol(:, :, 1:2:end), 2);
    SDO.vol = permute(SDO.vol(),[2 3 1]);
    SDO.Done();
  end
end
