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

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case 'nearest' % simplest but by far fastest int. method
    tic;
    SDO.VPrintF('   Nearest neighbor interpolation...');

    SDO.vol = SDO.raw;
    % SDO.raw = []; % FIXME uncomment this to make more memory efficient
    SDO.vol = raw(:,SDO.Pos.nearIdx);
    % % replace shot values with nearest-neighbour values of position
    SDO.vol = reshape(raw',SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),[]);
    SDO.Done();

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case {'linear'} % keep this as an option as it's the only
    % memory efficient way to get high resolution and smooth volumes!
    % but man it is sloooooow
    SDO.VPrintF('   Scattered data, linear-interpolation:');
    SDO.Print_Indent();
    [xGrid,yGrid] = meshgrid(SDO.Pos.x,SDO.Pos.y);
    SDO.vol = zeros(SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),SDO.nSamples);
    nLayers = SDO.nSamples; % each zIdx is forms it's own layer
    cpb = prep_console_progress_bar(nLayers);
    cpb.start();
    cpb.setValue(0);
    for iLayer = 1:nLayers
      SDO.ScatInterp.Values = double(SDO.raw(iLayer,:)');
      SDO.vol(:,:,iLayer) = SDO.ScatInterp(xGrid,yGrid)';
      text = sprintf('done: %d/%d.', iLayer, nLayers);
      cpb.setText(text);
      cpb.setValue(iLayer);
    end
    cpb.stop();
    SDO.VPrintF('   Scattered data interpolation took %2.1f s.\n',toc);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case {'par-linear'}
    tic;
    SDO.VPrintF('   Scattered data, parallel linear-interpolation:\n');
    try
      nLayers = SDO.nSamples; % each zIdx is forms it's own layer
      cpb = prep_console_progress_bar(nLayers);

      %--------------------------------------------------------------------------
      SDO.VPrintF('   Distributing work on %i layers:',nLayers);
      [xGrid,yGrid] = meshgrid(SDO.Pos.x,SDO.Pos.y);
      parPool = gcp();
      ticBytes(parPool);
      f = repmat(parallel.FevalFuture(),1,nLayers);
      cpb.start();
      cpb.setValue(0);
      for iLayer = 1:nLayers
        shotValues = double(SDO.raw(iLayer,:)');
        f(iLayer) = parfeval(parPool,@shots_to_plane,1,...
                            SDO.ScatInterp,shotValues,xGrid,yGrid);
        text = sprintf('done: %d/%d.', iLayer, nLayers);
        cpb.setText(text);
        cpb.setValue(iLayer);
      end
      cpb.stop();
      %--------------------------------------------------------------------------
      SDO.VPrintF('   Collecting work for %i layers:',nLayers);
      SDO.vol = zeros(SDO.Pos.nSteps(1),SDO.Pos.nSteps(2),nLayers);
      cpb.start();
      cpb.setValue(0);
      for iLayer = 1:SDO.nSamples
        [completedIdx,result] = fetchNext(f);
        SDO.vol(:,:,completedIdx) = result';
        text = sprintf('done: %d/%d.', iLayer, nLayers);
        cpb.setText(text);
        cpb.setValue(iLayer);
      end
      cpb.stop();
      % SDO.vol = permute(SDO.vol,[2 1 3]);
      SDO.VPrintF('   Scattered data interpolation took %2.1f s.\n',toc);
      tocBytes(gcp);
    catch em
      cancel(f); % make sure to cancel computations
      error(em);
    end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  case {'gridfit'}
    SDO.VPrintF('   Gridfit bilinear-interpolation...');
    SDO.Verbose_Warn('To be implemented....');
  end

end
