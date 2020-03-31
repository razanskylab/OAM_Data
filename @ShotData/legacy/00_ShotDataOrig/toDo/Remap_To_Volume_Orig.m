% [out] = Remap_To_Volume(SDO,In) @ SDO
% text here
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Remap_To_Volume(SDO)
  SDO.Sync_Subclass_Settings(); % be safe, update the subclass outputs

  short_warn('Remap_To_Volume not yet implemtented...');
  %
  % Conf.interpolation = 4;
  % % possible settings:
  % % 0 = nearestOld -> very fast
  % % scatteredInterpolant based:
  % % 1 = linear, 2 = nearestNew, 3 = natural
  % % 4 = gridfit based, bilinear interpolation with smoothing
  % Conf.extrapolationMethod = 'none'; % 'nearest', 'linear'
  % Conf.downSampleFactor = [1 1]; % if <1 will interpolate!
  % dp_remap_3d



  % Remap -> make its own function
  % get rid of usRaw there if needed...
  % rawUs = SDO.rawUs;
  % if ~SDO.cacheRawData % no caching, clean up to save memory
  %   SDO.rawUs = [];
  %   SDO.rawDataIsCached = false; % need to load data again if processing again...
  % end

  % [D] = remap_3d(D,Conf);
  % interpolates the 3D fastscan data and maps to the regular grid defined
  % by XPosVec and YPosVec for further post processing

  % convert pos vectors to double because triangulation and interpolation need that
  % NOTE will single work as well?
  D.Scan.nX = D.Scan.nSteps(2);
  D.Scan.nY = D.Scan.nSteps(1);
  idealXPosVec = double(SDO.x);
  idealYPosVec = double(SDO.y);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % get ideal (equally spaced) parametric x and y vectors (f(index))
  % with each Xr(i)|Yr(i) pair defining the postion in the now regular grid
  % for each shot, i.e:
  % Xr(1)|Yr(1) => Shot(1),
  % Xr(2)|Yr(2) => Shot(2),
  % ... ,
  % Xr(n)|Yr(n) => Shot(n)

  if Conf.Wiggle.doRemove % wiggle has been removed, affects shape of regular vector
    regularX = repmat(idealXPosVec,1,D.Scan.nY)'; % zig-zag curve
  else
    regularX = repmat([idealXPosVec fliplr(idealXPosVec)],1,floor(D.Scan.nY/2))';
    if mod(D.Scan.nY,2)
      %uneven number of samples along y, add XPosVec vector in regularX after remap
      regularX = [regularX' idealXPosVec]';
    end
  end
  regularY = repelem(idealYPosVec,D.Scan.nX)'; % staircase

  % convert pos vectors to double because triangulation and interpolation need that
  realXPos = double(D.Scan.xPos(:));
  realYPos = double(D.Scan.yPos(:));

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % find difference between sampled position and nearest grid position
  DT = delaunayTriangulation(realXPos,realYPos);
  nearIdx = nearestNeighbor(DT,regularX,regularY);
  D.Dr = sqrt((realXPos(nearIdx)-regularX).^2 + ...
    (realYPos(nearIdx)-regularY).^2);

  % Starting the interpolation fun...
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % old, fast but inacurate nearest neighbor interpolation %%%%%%%%%%%%%%%%%%%%%
  if (Conf.interpolation == 0)
    disp('Nearest neighbor interpolation.');
    % replace shot values with nearest-neighbour values of position
    D.Us.raw = D.Us.raw(nearIdx,:);
    % transform to full 3D matrix
    disp('Creating 3D signal matrix.');
    % [D] = get_full3D(D,Conf);
    D.Us.full3d = reshape(D.Us.raw,D.Scan.nX,D.Scan.nY,D.Scan.nSamplesPerShot);
  elseif (Conf.interpolation == 4)
    disp('Gridfit bilinear interpolation.');
    full3d = gridfit_interpolation(D); % defined here in this file
    D.Us.full3d = full3d;
  else
    disp('Scattered data interpolation.');
    full3d = scattered_interpolation(D,Conf);
    D.Us.full3d = full3d;
  end

  % with ExtrapolationMethod = 'none' evaluating at the border
  % often creates NaN...we don't like NaNs!
  D.Us.full3d(isnan(D.Us.full3d)) = 0;
end

  % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  % remap_3d defintion ends here
  % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



  %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  % Function Definitions Start Here
  %>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % gridfit_interpolation
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function full3d = gridfit_interpolation(D)
    % nicer images, slighty slower gridinterpolant

    [~,parForArgument] = run_parallel_processing();

    % convert pos vectors to double because triangulation and interpolation need that
    idealXPosVec = double(SDO.x);
    idealYPosVec = double(SDO.y);
    realXPos = double(D.Scan.xPos(:));
    realYPos = double(D.Scan.yPos(:));

    usShots = double(D.Us.raw); % convert to double prior to interpolation

    % interpolate all z-slices seperateley
    full3d = zeros(D.Scan.nY,D.Scan.nX,D.Scan.nSamplesPerShot);
    fprintf('Interpolating (bilinear) x-y data...');
    parfor (iSlice = 1:D.Scan.nSamplesPerShot,parForArgument)
      full3d(:,:,iSlice) = gridfit_joe(realXPos,realYPos,usShots(:,iSlice),idealXPosVec,idealYPosVec);
    end
    fprintf('done!\n');
    full3d = permute(full3d,[2,1,3]);

    % convert back to single, no need to store and display more than single precsion
    full3d = single(full3d);
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % scattered_interpolation
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function full3D = scattered_interpolation(D,Conf)
    % full3D = scattered_interpolation();

    [nWorkers,parForArgument] = run_parallel_processing();

    % convert pos vectors to double because triangulation and interpolation need that
    idealXPosVec = double(D.XPosVec);
    idealYPosVec = double(D.YPosVec);
    realXPos = double(D.Scan.xPos(:));
    realYPos = double(D.Scan.yPos(:));

    % convert to double prior to interpolation
    usShots = double(D.Us.raw)';


    % prepare regular meshgrid for interpolation
    [xGrid,yGrid] = meshgrid(idealXPosVec,idealYPosVec);

    % create scatteredInterpolant object
    scatInterpolant = scatteredInterpolant(realXPos,realYPos,squeeze(usShots(1,:)'));
    scatInterpolant.Method = Conf.interpolationMethod;
    scatInterpolant.ExtrapolationMethod = Conf.extrapolationMethod;

    % run interpolation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % take care of case where D..Scan.nSamplesPerShot/nWorkers is not an integer number
    % this is done by make all slices bigger except the last
    sliceThickness = ceil(D.Scan.nSamplesPerShot/nWorkers);
    lastSliceThickness = D.Scan.nSamplesPerShot-sliceThickness*(nWorkers-1);
    % sliceThicknessDiff = sliceThickness-lastSliceThickness;

    tic
    % find zSlice range for the separate workers and get seprate interpolants
    for iWorker = 1:(nWorkers)
      Interp{iWorker} = scatInterpolant; % get nWorkers copies of interpolant
      zSlices(iWorker,:) = (iWorker-1)*sliceThickness+(1:sliceThickness);
    end
    % last workerSlice is different as it can be smaller than the rest
    % padd missing values with last index
    zSlices(end,lastSliceThickness:end) = zSlices(end,lastSliceThickness);

    interpDataTemp = zeros(iWorker,sliceThickness,size(xGrid,1),size(xGrid,2));
    fprintf(['Interpolating (' Conf.interpolationMethod ') x-y data...']);
    parfor (iWorker = 1:nWorkers,parForArgument)
      for currentSlice = 1:sliceThickness
        sliceIndex = zSlices(iWorker,currentSlice);
        Interp{iWorker}.Values = squeeze(usShots(sliceIndex,:)');
        % run the actual interpolation
        interpDataTemp(iWorker,currentSlice,:,:) = Interp{iWorker}(xGrid,yGrid);
      end
    end

    %% reformat interpolated data to fit [x,y,z] dimension style --------------
    full3D = zeros(D.Scan.nX,D.Scan.nY,D.Scan.nSamplesPerShot);
    for iWorker = 1:nWorkers
      for currentSlice = 1:sliceThickness
        sliceIndex = zSlices(iWorker,currentSlice);
        full3D(:,:,sliceIndex) = squeeze(interpDataTemp(iWorker,currentSlice,:,:))'; %slow
      end
    end
    toc
    % convert back to single, no need to store and display more than single precsion
    full3D = single(full3D);
    fprintf('done!\n');
  end

end
