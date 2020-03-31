% [out] = Remap_Max_Image(SDO,In) @ SDO
% takes max amp of US.raw and
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Remap_Max_Image(SDO)
  tic;
  SDO.Sync_Subclass_Settings(); % be safe, update the subclass outputs
  SDO.VPrintF('Remapping max-amp 2D shots to regular image:\n');

  switch SDO.reMapMethod
  case 'nearest' % simplest but by far fastest int. method
    SDO.VPrintF('   Nearest neighbor interpolation...');
    regShots = SDO.maxShots(SDO.Pos.nearIdx);
    % remap reshape the regular space 1 shot vector (max shots) into 2D image
    regIm = reshape(regShots,SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),[]);

    regShotsDepth = SDO.maxShotsIdx(SDO.Pos.nearIdx);
    % remap reshape the regular space 1 shot vector (max shots) into 2D image
    regDepthMap = reshape(regShotsDepth,SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),[]);
  case {'linear','par-linear'}
    SDO.VPrintF('   Scattered data linear-interpolation...');
    [xGrid,yGrid] = meshgrid(SDO.Pos.x,SDO.Pos.y);
    SDO.ScatInterp.Values = double(SDO.maxShots');
    regIm = SDO.ScatInterp(xGrid,yGrid)';
    SDO.ScatInterp.Values = double(SDO.maxShotsIdx');
    regDepthMap = SDO.ScatInterp(xGrid,yGrid)';
  case {'idw'} % IDEA -> try and find this implemented on GPU?
    % works but is slow as hell
    % SDO.VPrintF('   Inverse distance interpolation...');
    % regShots = gIDW(SDO.Pos.xS,SDO.Pos.yS,SDO.maxShots,SDO.Pos.xReg,SDO.Pos.yReg,-1,'n',5);
    % regIm = reshape(regShots,SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),[]);
  case {'gridfit'}
    SDO.VPrintF('   Gridfit bilinear-interpolation...');
    SDO.Verbose_Warn('To be implemented....');
  end
  SDO.maps{1} = regIm;
  SDO.depthMap = regDepthMap;
  SDO.Done();

  % Starting the interpolation fun...
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % old, fast but inacurate nearest neighbor interpolation %%%%%%%%%%%%%%%%%%%%%


  % if (Conf.interpolation == 0)
  % replace shot values with nearest-neighbour values of position
  % M = Maps(double(regIm));
  % M.Norm();
  % M.ImFilter.claheLim = 0.001;
  % M.ImFilter.claheDistr = 'uniform';
  % M.xy = M.ImFilter.Apply_CLAHE();
  % M.Plot();

  % imagescj(regIm);
  % K>> plot(SDO.Pos.nearIdx)
  % K>> regIm = reshape(reg',100,100,[]);
  % K>> imagescj(regIm)
  % K>> regIm2 = reshape(reg,100,100,[]);
  % K>> imagescj(regIm2)
  % K>> close all
  % K>> regIm2 = reshape(reg,100,100,[]);
  % K>> dbquit all


  % SDO.raw = SDO.raw(:,SDO.Pos.nearIdx);
  % transform to full 3D matrix
  % disp('Creating 3D signal matrix.');
  % [D] = get_full3D(D,Conf);

  % SDO.full3d = reshape(SDO.raw,SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),SDO.nSamples);

  % SDO.full3d = reshape(SDO.raw',SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),[]);


  % elseif (Conf.interpolation == 4)
  %   disp('Gridfit bilinear interpolation.');
  %   SDO.full3d = gridfit_interpolation(D); %
  % else
  %   disp('Scattered data interpolation.');
  %   SDO.full3d  = scattered_interpolation(D,Conf);
  % end

  % with ExtrapolationMethod = 'none' evaluating at the border
  % often creates NaN...we don't like NaNs!
  % SDO.full3d(isnan(SDO.full3d)) = 0;
end

% % remapping from reg x-y to 3d
% shot = 1:20; % 1x20
% allShots = repmat(shot,9,1); % 9 x 20
% allShots = bsxfun(@plus,allShots',100:100:900); % multiply by 1:9 to make unique vectors
% allShots(:,1); % first shot
% volume = reshape(allShots,3,3,[]);
%  min(volume,[],3)
