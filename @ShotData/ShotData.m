% ShotData Class
% (johannesrebling@gmail.com), 2018

% toDo
% figure out how to handle ROI, XYZ, DR, etc...

classdef ShotData < BaseClass

  % processing settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % settings which do have an effect on the final 3d volumes
  properties
    % zrange with [startIdx,endIdx]
    % if endIdx = Inf, load from startIdx:end
    % these are absolute values! ALWAYS!
    zCrop(1,2) {mustBeNumeric} = [0 0];

    % jitter removal settings TODO
    correctJitter(1,1) {mustBeNumericOrLogical} = true;

    % resample US data?
    % downsampling for faster processing
    % upsampling for nicer images?
    % NOTE Needs to be tested!!! especially for space upsampling!
    reSampleFactors(1,2) {mustBeNumeric, mustBeFinite} = [1 1];
                          % [time-signals space-signals]
                          % > 1 = downsampling, using integers is very fast!
                          % < 1 = upsampling

    % 0 = pos. and neg. signals, 1 = pos. only, -1 = neg. signals only, % 2 = hilbert
    signalPolarity(1,1) {mustBeNumeric, mustBeFinite} = 0;

    reMapMethod {mustBeMember(reMapMethod,{...
      'reshape',... % reshape, no interpolation
      'nearest',... % super fast, delaunayTriangulation based interpolation
      'linear',... % scatteredInterpolant based, slow but accurate linear interpolation
      'par-linear',...
      'gridfit',... % bilinear, gridfit based interpolation FIXME causing articats? Not implemented!
      })} = 'nearest';

    reMapFactor (1,1) double {mustBeNumeric, mustBeFinite} = 1;
      % <1 interpolation, >1 reduction, is multiplied by Pos.dr so it affects
      % x,y and xReg and yReg which are used for intrpolation and plotting
      % NOTE reMapFactor is applied prior to Remap_Data
      % only applied at remapping, i.e. not during Position processing, reduction etc
      % so its possible to reduce data by factor 2 but the upsample during remapping
    doRemapFast(1,1) {mustBeNumericOrLogical} = true;
  end

  % output settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % influencing output during processing but not final volume
  properties
    % only load cropped data, no need for any more z-cropping...
    % saves memory and is faster!
    loadCroppedData(1,1) {mustBeNumericOrLogical} = true;

    % settings/methods stored in sub classes
    Out = OutputProperties(); % see OutputProperties class
    % output/plotting options
    useUnits(1,1) {mustBeNumericOrLogical} = false;
  end


  % properties storing subclasses %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  properties % subclasses
    Filter = FilterClass.empty; % see class definition
    Pos = PosData.empty;
  end

  % properties storing data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  properties
    mode(1,:) char = ''; % set function ensures only valid modes are used!
      % see validate_mode fct.
    raw(:,:) {mustBeNumeric} = [];
    % this is where the 2d data is stored for all processing until the final
    % remapping, i.e. during cropping, filtering, shot removal, jitter removal, etc...
    % form: allShots(samplesPerShot,nShots)

    % this is the final goal...getting nice 3d data!
    vol(:,:,:) single {mustBeNumeric};
      % NOTE any way to do all processing as int16 by scaling?
      % remapping only works with single/double unless only using nearest neighbour

    % xy, xz and yz maps with maps{1} = xy, maps{2} = xz and maps{3} = yz
    maps(1,3) = cell(1,3);
    depthMap(:,:) {mustBeNumeric} = [];

    % vectors storing geometry of scanned region etc, read from scan info
    prf(1,1) {mustBeNumeric} = 0; % [Hz], shot frequency, can be changed when resampled
    dt(1,1) {mustBeNumeric} = 0; % dt = 1./df, sampling period, can be changed when reSampleStepSize ~= 1
      % store jitter detected in PD signal here to correct both PD and US shots
    jitter(1,:) {mustBeNumeric} = [];
  end

  % not showing up as property, but we can access and change if needed
  properties (Hidden=true)
    isCropped(1,1) {mustBeNumericOrLogical} = 0; % true when zRange was applied, i.e. when nSamples <= zRange
    ScatInterp = []; % scattered interpolant to be used for image and volumetric remapping
  end

  % depended properties are calculated from other properties
  properties (Dependent = true)
    % maps, not calculated from volume but stored in maps property
    xy; xz; yz;

    % maps, calculated from volume
    xyVol; xzVol; yzVol; xyDepth;
      % NOTE using two different maps allows storing processed maps in maps Property
      % while the raw maps can always be easily retrieved from the volumetric data

    zRange; % used to crop data based on values provided in zCrop


    % these are regular, absolute x,y,z vectors, based on ROI, with length = nSteps
    % calculate based on ROI, dr and nSteps!
    z; % either idx or depth, depending on useUnits option, takes into account
      % crop range and downsample factors

    zRel;  % same as z but centered at zero
    depth; % same as z, but always in mm if dt is known, otherwise empty


    nSamples; % updated when z-crop is applied as well!
    nShots; % get function, so it's updated when size of us/pd changes
    df; % 1/dt

    % convenient stats / shots / etc
    maxAmpIdx; % index of shot with the largest amplitude
    maxAmpShot;  % complete time signal for shot at maxAmpIdx
    maxAmpSpec;
    minAmpIdx; % index of shot with the largest amplitude
    minAmpShot;  % complete time signal for shot at maxAmpIdx
    minAmpSpec;
    freq;

    maxShot; % max of all shots, i.e. size = nSamples
    minShot; % min of all shots, i.e. size = nSamples
    absMaxShot; % max(abs(raw)) of all shots, i.e. size = nSamples
    meanShot;  % mean of all shots, i.e. size = nSamples
    stdShot;  % std of all shots, i.e. size = nSamples

    maxShots; % max value of each shot, i.e. size=nShots
    maxShotsIdx; % idx of max value of each shot
    minShots; % min value of each shot, i.e. size=nShots
    meanShots; % mean of each shot, i.e. size=nShots
    stdShots; % std of each shot, i.e. size=nShots

    % convenience properties
    doFilter; % just check FSP.US.Filter.freq...
  end

  properties
  % defined in base class but this way we can have set/get in sublcasses, which
  % is % needed for FOAM processor
    silent(1,1) {mustBeNumericOrLogical} = false;
    verboseOutput(1,1) {mustBeNumericOrLogical} = true; % more detailed output to workspace...
    verbosePlotting(1,1) {mustBeNumericOrLogical} = false; % more figures...
    figureVisibility(1,:) char {mustBeMember(figureVisibility,{'on','off'})} = 'on';
  end


  % constant properties
  properties (Constant)
    SOS_WATER = 1498; % speed of sound in water, in m/s
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % constructor, desctructor, save obj
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  methods
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % constructor, called when class is created
    function SDO = ShotData()
      SDO.Filter = FilterClass(); % see class definition
      SDO.Pos = PosData();
      SDO.Sync_Subclass_Settings();
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor: Mainly used to close the serial connection correctly
    function delete(~)
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % when saved, hand over only properties stored in saveObj
    function SaveObj = saveobj(SDO)
      % only save public properties of the class if you save it to mat file
      % without this saveobj function you will create an error when trying
      % to save this class
      % SaveObj.pos = SDO.pos;
      SaveObj = SDO;
    end
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% "Standard" methods, i.e. functions which can be called by the user and by
  % the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access = private)

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
  %%===========================================================================
    function set.mode(F,inMode)
      F.mode = validate_mode(inMode);
    end

  %%===========================================================================
    function xy = get.xy(SDO)
      if isempty(SDO.maps) && ~isempty(SDO.vol)
        SDO.maps{1} = SDO.xyVol;
        SDO.maps{2} = SDO.xzVol;
        SDO.maps{3} = SDO.yzVol;
      end
      xy = squeeze(SDO.maps{1});
    end
    function xz = get.xz(SDO)
      if isempty(SDO.maps) && ~isempty(SDO.vol)
        SDO.maps{1} = SDO.xyVol;
        SDO.maps{2} = SDO.xzVol;
        SDO.maps{3} = SDO.yzVol;
      end
      xz = squeeze(SDO.maps{2});
    end
    function yz = get.yz(SDO)
      if isempty(SDO.maps) && ~isempty(SDO.vol)
        SDO.maps{1} = SDO.xyVol;
        SDO.maps{2} = SDO.xzVol;
        SDO.maps{3} = SDO.yzVol;
      end
      yz = squeeze(SDO.maps(3,:,:));
    end

    %%===========================================================================
    function xyVol = get.xyVol(SDO)
      xyVol = squeeze(max(SDO.vol,[],3)); % projext along z
      % rotate instaed of permute, to get correct image orientation
      xyVol = imrotate(xyVol,180);
        % NOTE this 180 deg is because of the volume projection...
    end
    function xyDepth = get.xyDepth(SDO)
      [~,xyDepth] = max(SDO.vol,[],3); % projext along z
      xyDepth = squeeze(xyDepth);
      % rotate instaed of permute, to get correct image orientation
      xyDepth = imrotate(xyDepth,180);
        % NOTE this 180 deg is because of the volume projection...
    end
    function xzVol = get.xzVol(SDO)
      xzVol = squeeze(max(SDO.vol,[],2)); % projext along y
    end
    function yzVol = get.yzVol(SDO)
      yzVol = squeeze(max(SDO.vol,[],1)); % projext along x
    end

    %%===========================================================================
    function zRange = get.zRange(SDO)
      % automatically get zRange
      % kinda complicated here, so we use some simplifications...
      hasZCrop = any(SDO.zCrop);
      hasSamples = any(SDO.nSamples);
      useFullRange = isinf(SDO.zCrop(2));

      % some basic sanity checks...
      if hasZCrop
        if SDO.zCrop(1) < 1
          short_warn('SDO.zCrop(1) was automatically corrected to 1 (startIdx was <1)!');
          SDO.zCrop(1) = 1;
        end

        if SDO.zCrop(1) > SDO.zCrop(2)
          short_warn('SDO.zCrop was automatically flipped (startIdx > stopIdx)!');
          SDO.zCrop = flip(SDO.zCrop);
        end
      end

      if ~hasZCrop && ~hasSamples
        zRange = []; % cant get a meaningful zRange...
      elseif ~hasZCrop && hasSamples % we know and use full range when no zRange specified
        zRange = 1:SDO.nSamples; %
        SDO.zCrop = [min(zRange) max(zRange)];
      elseif hasZCrop && hasSamples % zRange was specified, make sure it makes sense...
        if useFullRange
          zRange = SDO.zCrop(1):SDO.nSamples; % use full range
        elseif all(isfinite(SDO.zCrop))
          zRange = SDO.zCrop(1):SDO.zCrop(2); % use provided cropped range
        else
          error('Can''t handle this zCrop/zRange!');
        end
        SDO.zCrop = [min(zRange) max(zRange)];
      elseif hasZCrop && ~hasSamples && useFullRange % i want to crop to end during loading...
        zRange = [];
%         short_warn('Need to figure out how large the matrix is!'); % this should never happen!
      elseif hasZCrop && ~hasSamples % i want to crop to end during loading...
        zRange = SDO.zCrop(1):SDO.zCrop(2); % use provided cropped range
      end
    end

    %%===========================================================================
    function nSamples = get.nSamples(SDO)
      if ~isempty(SDO.raw)
        nSamples = size(SDO.raw,1);
      else
        nSamples = 0; % better than [] as for loops etc won't fail!
      end
    end

    %%===========================================================================
    function nShots = get.nShots(SDO)
      if ~isempty(SDO.raw)
        nShots = size(SDO.raw,2);
      else
        nShots = 0; % better than [] as for loops etc won't fail!
      end
    end

    function z = get.z(SDO)
      z = SDO.zRange();
      % take care if we downsampled before...
      % isIntegerDownSampling = ~any(mod(SDO.reSampleFactors(1),1));
      % if isIntegerDownSampling
        % z = z(1:SDO.reSampleFactors(1):end);
      % end
      if SDO.useUnits
        switch SDO.mode
        case 'us'
          pulseDelay = 8*1e-6;
          dZ = 1./SDO.df*SDO.SOS_WATER*1e3./2; % dZ in mm/samples
        case {'edge','dye','onda32','onda64'}
          pulseDelay = -0.1*1e-6; % pulse comes 100 ns after trigger
          dZ = 1./SDO.df*SDO.SOS_WATER*1e3; % dZ in mm/samples
        end
        % pulse starts 8us before first sample, ie. z(1)
        initDelay = round(pulseDelay*SDO.df);
        z = (1:SDO.nSamples) + initDelay;
        z = z.*dZ;
      end
    end


    function zRel = get.zRel(SDO)
      zRel = SDO.z - mean(SDO.z); % center around zero
    end

    function depth = get.depth(SDO)
      % same as z- but in mm always
      if ~isempty(SDO.dt)
        z = SDO.zRange();
        % take care if we downsampled before...
        isIntegerDownSampling = ~any(mod(SDO.reSampleFactors(1),1));
        if isIntegerDownSampling
          z = z(1:SDO.reSampleFactors(1):end);
        end
        if strcmp(SDO.mode,'us')
          depth = z*SDO.dt*SDO.SOS_WATER*1e3./2;
          % NOTE just keep the /2 its correct even if Joe has a hard time
          % believing it. Sincerly, Joe...
        else % oa based mode, no division by 2
          depth = z*SDO.dt*SDO.SOS_WATER*1e3;
          % NOTE just keep the /2 its correct even if Joe has a hard time
          % believing it. Sincerly, Joe...
        end
      else
        depth = [];
      end
    end


    %%===========================================================================
    function df = get.df(SDO)
      df = 1./SDO.dt;
      if ~isempty(df) && (df == 1 || df == 0)
        short_warn('df = 1/0, you probably still need to set it.');
      end
    end

    %%===========================================================================
    function maxAmpIdx = get.maxAmpIdx(SDO)
      [~,maxAmpIdx] = max(max(abs(SDO.raw)));
    end
    function maxAmpShot = get.maxAmpShot(SDO)
      maxAmpShot = squeeze(SDO.raw(:,SDO.maxAmpIdx));
    end
    function minAmpIdx = get.minAmpIdx(SDO)
      [~,minAmpIdx] = min(max(abs(SDO.raw)));
    end
    function minAmpShot = get.minAmpShot(SDO)
      minAmpShot = squeeze(SDO.raw(:,SDO.minAmpIdx));
    end

    %%===========================================================================
    function freq = get.freq(SDO)
      % nfft used in fast_fft_pro()
      nfft = 2^nextpow2(SDO.nSamples); % Next power of 2 from number of time samples
      freq = linspace(0,1,nfft/2+1)*SDO.df/2;
    end

    function maxAmpSpec = get.maxAmpSpec(SDO)
      if SDO.dt && ~isempty(SDO.maxAmpShot)
        [~, maxAmpSpec] = fast_fft_pro(SDO.dt,SDO.maxAmpShot,0,0,0);
      else
        maxAmpSpec = [];
      end
    end

    function minAmpSpec = get.minAmpSpec(SDO)
      if SDO.dt && ~isempty(SDO.minAmpShot)
        [~, minAmpSpec] = fast_fft_pro(SDO.dt,SDO.minAmpShot,0,0,0);
      else
        minAmpSpec = [];
      end
    end

    %%===========================================================================
    % mean / max / std of size = nSamples
    function maxShot = get.maxShot(SDO)
      maxShot = squeeze(max(SDO.raw,[],2));
    end
    function minShot = get.minShot(SDO)
      minShot = squeeze(min(SDO.raw,[],2));
    end
    function absMaxShot = get.absMaxShot(SDO)
      absMaxShot = squeeze(max(abs(SDO.raw),[],2));
    end
    function meanShot = get.meanShot(SDO)
      meanShot = squeeze(mean(SDO.raw,2));
    end
    function stdShot = get.stdShot(SDO)
      stdShot = squeeze(std(single(SDO.raw),[],2));
    end

    %%===========================================================================
    % mean / max / std of size = nSamples
    function maxShots = get.maxShots(SDO)
      [maxShots,~] = max(SDO.raw);
      maxShots = squeeze(maxShots);
    end
    function maxShotsIdx = get.maxShotsIdx(SDO)
      [~,maxShotsIdx] = max(SDO.raw);
      maxShotsIdx = squeeze(maxShotsIdx);
    end
    function minShots = get.minShots(SDO)
      minShots = squeeze(min(SDO.raw));
    end
    function meanShots = get.meanShots(SDO)
      meanShots = squeeze(mean(SDO.raw));
    end
    function stdShots = get.stdShots(SDO)
      stdShots = squeeze(std(single(SDO.raw)));
    end

    function doFilter = get.doFilter(SDO)
      doFilter = any(SDO.Filter.freq);
    end
  end

end
