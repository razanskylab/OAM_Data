% [out] = Remap_Max_Image(SDO,In) @ SDO
% takes max amp of US.raw and
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Remap_Max_Image(SDO)
  tic;
  SDO.Sync_Subclass_Settings(); % be safe, update the subclass outputs
  SDO.VPrintF('Remapping max-amp 2D shots to regular image:\n');

  switch SDO.reMapMethod

  case 'reshape' % simplest but by far fastest int. method
    tic;
    SDO.VPrintF('   Reshaping...');
    [regIm,regDepthMap] = max(SDO.raw);

    regIm = reshape(regIm,SDO.Pos.nSteps(1),SDO.Pos.nSteps(2));
    % we scan back and forth, this flips every second line to allign them
    regIm(:,1:2:end) = flip(regIm(:,1:2:end),1);
    regIm = imrotate(regIm,90);

    regDepthMap = reshape(regDepthMap,SDO.Pos.nSteps(1),SDO.Pos.nSteps(2));
    % we scan back and forth, this flips every second line to allign them
    regDepthMap(:,1:2:end) = flip(regDepthMap(:, 1:2:end), 1);
    regDepthMap = imrotate(regDepthMap,90);
  end
  SDO.maps{1} = regIm;
  SDO.depthMap = regDepthMap;
  SDO.Done();

end
